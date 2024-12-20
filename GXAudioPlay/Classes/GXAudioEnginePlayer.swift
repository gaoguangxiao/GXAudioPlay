//
//  GXAudioEnginePlayer.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/11/6.
//

import Foundation
import AVFoundation
import RxSwift

//public protocol GXAudioEnginePlayerDelegate: NSObjectProtocol {
//    //播放结束，手动停止，或者播放完毕
//    func engineDidFinishPlaying(_ player: GXAudioEnginePlayer)
//}

// 可使用

public class GXAudioEnginePlayer: NSObject {
    
    public var track: String = ""
    
    private let engine = AVAudioEngine()//音频引擎
    private let player = AVAudioPlayerNode() //播放节点
    
    private let player2 = AVAudioPlayerNode() //播放节点
    
    //音量单元
    private let volumeEffect = AVAudioUnitEQ()
    
    private let timePitch = AVAudioUnitTimePitch() //播放变速变调节点
    
    private var isPeriodicTimer = false
    //    private let rateEffect = AVAudioUnitVarispeed() //音频播放速度单元 不可用，速率的改变会改变音高
    //    private let delay = AVAudioUnitDelay() //延迟
    //    public weak var delegateEngine : GXAudioEnginePlayerDelegate?
    
    //    private let unitReverB = AVAudioUnitDistortion()
    
    var skipFrame: AVAudioFramePosition = 0//用于记录从某帧开始播放
    var seekStatus = false //设置播放进度时，此值为true。因为会停止当前PlayerNode造成事件回调，因此增加判断
    
    var currentAudioFile: AVAudioFile? //当前播放引擎播放的文件
    var currentAudioPCMBuffer: AVAudioPCMBuffer? //当前播放引擎播放的文件缓存
    
    public var playEventsBlock: ((PTAudioPlayerEvent)->())?
    
    public var timeEvent: Bool = false
    
    public var status : PTAudioPlayerEvent = .None
    
    public var disposeBag = DisposeBag()
    
    public var startTime: Date = Date()
    
    public var playbackDuration: Double = 0
    
    var displayLink: CADisplayLink?
    //遵循播放协议，但是存储属性不能写入扩展，因此写入实体
    public var loop: Bool = false
        
    public var isLaunchOverTimer: Bool = false
    
    public var overTimer: Timer?
    
    public var canPlayResult: Bool = false
    
    public var isRunning: Bool = false
    
    public var canPlayResultCount: Double = 1
    
    public var playingEndTime: Double = 0
    
    public var currentPlayCount: Double = 0
    
    public var audioPath: String = ""
    
    public override init() {
        //添加播放节点
        engine.attach(player)
        //添加第二个播放节点
        engine.attach(player2)
        //添加音量
        engine.attach(volumeEffect)
        //添加变速变调节点
        engine.attach(timePitch)
        
        engine.connect(timePitch, to: engine.mainMixerNode, format: nil)
        //链接EQ节点到
        engine.connect(volumeEffect, to: timePitch, format:nil)
        //链接播放节点到引擎的`volumeEffect`
        engine.connect(player, to: volumeEffect, format: nil)
        //链接播放节点
        engine.connect(player2, to: engine.mainMixerNode, format: nil)
        //        engine.connect(volumeEffect, to: engine.mainMixerNode, format: nil)
        
        //预先准备资源
        engine.prepare()
        //打开引擎开关
        try? engine.start()
        
        //默认为0
        skipFrame = 0
        
        //设置音量
        //        player.volume = 1.0
        //播放速率
        //        player.rate = 1.0 调节有限
        
        timePitch.rate = 1.0
        //        timePitch.pitch = -800
        
        //        rateEffect.rate = 1.0
        //1、获取 主混合节点
        //        let audioFomat = engine.mainMixerNode.outputFormat(forBus: 0)
        //
        //        //
        //        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: audioFomat) { buffer, when in
        //            guard let channelData = buffer.floatChannelData, let updater = self.updater else {
        //                return
        //            }
        //        }
        
    }
    
    public var currentNodeTime: AVAudioTime? {
        guard let lastRenderTime = player.lastRenderTime,let playerTime = player.nodeTime(forPlayerTime: lastRenderTime) else {
            return nil
        }
        return playerTime
    }
    
    public var currentPlayTime: AVAudioTime? {
        guard let lastRenderTime = player.lastRenderTime,let playerTime = player.playerTime(forNodeTime: lastRenderTime) else {
            return nil
        }
        return playerTime
    }
    
    //播放器返回的最新一个音频数据
    public var currentFrame: AVAudioFramePosition {
        guard let playerTime = currentPlayTime else {
            return 0
        }
        return playerTime.sampleTime + skipFrame
    }
    
    public var currentTime: Double {
        guard let playerTime = currentPlayTime else {
            return 0
        }
        return Double(playerTime.sampleTime + skipFrame)/playerTime.sampleRate
    }
    
    //获取audio时长
    public var duration: Float64 {
        get {
            if let audioFile = self.currentAudioFile {
                let duration = Double(audioFile.length) / Double(audioFile.fileFormat.sampleRate)
                return duration
            }
            if let buffer = self.currentAudioPCMBuffer {
                let duration = Double(buffer.frameLength) / Double(buffer.format.sampleRate)
                return duration
            }
            return 0
        }
    }
    
    public var frameLength: AVAudioFramePosition {
        get {
            if let audioFile = self.currentAudioFile {
                let duration = audioFile.length
                return duration
            }
            if let buffer = self.currentAudioPCMBuffer {
                let duration = buffer.frameLength
                return AVAudioFramePosition(duration)
            }
            return 0
        }
    }
    
    //播放本地URL
    public func play(fileURL fileUrl: URL) throws {
//        try self.setAVAudioSession()
        if let audioFile = setPlayAudioFile(fileUrl: fileUrl) {
            player.scheduleFile(audioFile, at: nil, completionHandler: nil)
            skipFrame = 0
            self.playEventsBlock?(.Playing(duration))
            play()
        }
    }
    
    //辅助音轨播放
    public func playSubAudio(fileURL fileUrl: URL) {
        guard let audioFile = try? AVAudioFile(forReading: fileUrl) else { return }
        player2.scheduleFile(audioFile, at: nil, completionHandler: nil)
        self.player2.play()
    }

    //播放两种音频，一种主音，一种尾音，尾音在主音结束播放，主音会循环播放
    public func playLoopMainAudio(fileMainURL fileUrl: URL , endFileUrl: URL) {
        if let _ = setAudioPCMBuffer(fileUrl: fileUrl) {
            self.playAudioBuffer(isLoop: true, endFileUrl: endFileUrl)
        }
    }
    
    private func playAudioBuffer(isLoop: Bool,endFileUrl: URL) {
        if let buffer = self.currentAudioPCMBuffer {
            skipFrame = 0
            player.scheduleBuffer(buffer, at: nil,options: .loops) {
                if self.status != .Ended {
                    if isLoop {
//                        self.playSubNoteAudio(fileURL:endFileUrl)
                        //
//                        self.playAudioBuffer(isLoop: isLoop,endFileUrl: endFileUrl)
                    }
                }
            }
            play()
        }
    }
    //播放尾音
    public func playSubNoteAudio(fileURL fileUrl: URL) {
        guard let audioFile = try? AVAudioFile(forReading: fileUrl) else { return }
        player2.scheduleFile(audioFile, at: nil, completionHandler: nil)
        self.player2.play()
    }
    
    //从某时刻 播放本地URL
    public func play(fileURL fileUrl: URL,time:Double) {
        if let audioFile = setPlayAudioFile(fileUrl: fileUrl){
            let sampleRate = audioFile.fileFormat.sampleRate
            //播放文件
            let startingFrame :AVAudioFramePosition = AVAudioFramePosition(time * sampleRate)
            skipFrame = startingFrame
            //判断要播放的帧是否超出文件
            if startingFrame >= audioFile.length{
                print("over frame max\(audioFile.length)")
                return
            }
            // 要根据总时长和当前进度，找出起始的frame位置和剩余的frame数量
            let frameCount : AVAudioFrameCount = AVAudioFrameCount(audioFile.length - startingFrame)
            // 指定开始播放的音频帧和播放的帧数
            player.scheduleSegment(audioFile, startingFrame: startingFrame, frameCount: frameCount, at: nil) {
                self.playEventsBlock?(.Ended)
            }
            play()
        }
    }
    
    /// URL 用PCM缓存播放
    /// - Parameter fileUrl: fileUrl description
    //    public func playpcm(fileURL fileUrl: URL) {
    //        self.playpcm(fileURL: fileUrl, options: .interrupts)
    //    }
    
    public func playpcm(fileURL fileUrl: URL,options:AVAudioPlayerNodeBufferOptions = .interrupts) {
        if let buffer = setAudioPCMBuffer(fileUrl: fileUrl) {
            skipFrame = 0
            player.scheduleBuffer(buffer, at: nil,options: options) {
                self.playEventsBlock?(.Ended)
            }
            play()
        } else {
            
        }
    }
    
    //播放pcm支持循环播放
    public func playpcmLoop(fileURL fileUrl: URL,options:AVAudioPlayerNodeBufferOptions = .interrupts) {
        if let _ = setAudioPCMBuffer(fileUrl: fileUrl) {
            self.playAudioBuffer()
        }
    }
    
    /// URL 用PCM缓存播放
    /// - Parameter fileUrl: <#fileUrl description#>
    public func plays(fileURL fileUrls: Array<URL>) {
        for s in fileUrls {
            guard let audioFile = try? AVAudioFile(forReading: s) else { return }
            player.scheduleFile(audioFile, at: nil) {
                self.playEventsBlock?(.Ended)
            }
            play()
        }
    }
    
    //播放本类中AudioFile
    private func playAudioFile() {
        if let audioFile = self.currentAudioFile {
            player.scheduleFile(audioFile, at: nil, completionHandler: nil)
            skipFrame = 0
            self.playEventsBlock?(.Playing(duration))
            play()
        }
    }
    
    private func playAudioBuffer() {
        if let buffer = self.currentAudioPCMBuffer {
            skipFrame = 0
            player.scheduleBuffer(buffer, at: nil,options: .interrupts) {
                if self.loop {
                    self.playEventsBlock?(.LoopEndSingle)
                    self.playAudioBuffer()
                }
            }
            play()
        }
    }
    
    //设置当前播放的AudioFile
    private func setPlayAudioFile(fileUrl: URL) -> AVAudioFile? {
        guard let audioFile = try? AVAudioFile(forReading: fileUrl) else { return nil }
        self.currentAudioFile = audioFile
        return audioFile
    }
    
    private func setAudioPCMBuffer(fileUrl: URL) -> AVAudioPCMBuffer? {
        guard let audioFile = setPlayAudioFile(fileUrl: fileUrl) else { return nil }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                            frameCapacity: AVAudioFrameCount(audioFile.length)) else { return nil }
        try? audioFile.read(into: buffer)
        self.currentAudioPCMBuffer = buffer
        return buffer
    }
    
    //主动获取帧数变化 仅仅处理
    @objc func monitorTimeChange() {
        //        print("播放时间---\(self.currentFrame)---\(self.frameLength)")
        if self.currentFrame >= self.frameLength {
            print("播放结束---")
            if loop {
                //                改为内部播放回调
                //                player.stop()
                //                playAudioBuffer()
            } else {
                if player.isPlaying {
                    self.playEventsBlock?(.Ended)
                   stop()
                }
            }
            return
        }
        
        if player.isPlaying , self.isPeriodicTimer {
            self.playEventsBlock?(.TimeUpdate(currentTime))
        }
    }
    
    //    -- MARK：功能键
    private func play() {
        startEndine()
        self.player.play()
        
        //增加定时回调
        if let displayLink = displayLink {
            //复用定时器
//            print("复用定时器")
        } else {
            //新建定时器
//            print("新建定时器")
            //添加
            displayLink = CADisplayLink(target: self, selector: #selector(monitorTimeChange))
            displayLink?.add(to: .current, forMode: .common)
        }
        
        displayLink?.isPaused = false
        //        播放进度回调
        
        //repeats为true会持续调用
        
        //        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] (_timer) in
        //            guard let `self` = self else {
        //                _timer.invalidate()
        //                return
        //            }
        //            if currentTime >= duration {
        //                print("播放结束---")
        //                if loop {
        //                    self.playAudioFile()
        ////                    self.setSeekToTime(seconds: 0)
        //                } else {
        //                    _timer.invalidate()
        //                    if player.isPlaying {
        //                        self.playEventsBlock?(.Ended)
        //                    }
        //                }
        //                return
        //            }
        //            if player.isPlaying {
        //                self.playEventsBlock?(.TimeUpdate(currentTime))
        //            }
        //        })
    }
    
    //延迟多久播放
    //    func play(time:AVAudioTime) {
    //        startEndine()
    //        self.player.play(at: time)
    //    }
    
    public func startEndine(){
        if !self.engine.isRunning {
            self.engine.prepare()
            try? self.engine.start()
        }
    }
    
    deinit {
        print("dealloc--\(self)")
    }
}

extension GXAudioEnginePlayer: GXAudioPlayerProtocol{
   

//    public func playSubAudio(fileURL fileUrl: URL) {
//        self.playSubAudio(fileURL: fileUrl)
//    }
    
    public var numberOfLoops: Int{
        get {
            1
        }
        set {}
    }
    
    public var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }
    
    public var playSpeed: Float {
        //        get { rateEffect.rate }
        //        set { rateEffect.rate = newValue }
        get { timePitch.rate }
        set { timePitch.rate = newValue }
        //        get { player.rate }
        //        set { player.rate = newValue }
        
    }
    
    
    public func removePeriodicTimer() {
        isPeriodicTimer = false
    }
    
    
    public func addPeriodicTimer() {
        isPeriodicTimer = true
    }
    
    //本地URL
    public func play(url: String) throws {
        
        //        if let uurl = URL(fileURLWithPath: url) {
        //播放缓存
        //        self.playpcm(fileURL: URL(fileURLWithPath: url), options: .interrupts)
        //        }
//        self.playpcm(fileURL: URL(fileURLWithPath: url))
        try self.play(fileURL:URL(fileURLWithPath: url))
        
    }
    
    //    public func play(fileURL fileUrl: String) {
    //        self.playAudioFile(fileURL:URL(string: fileUrl) ?? <#default value#>)
    //    }
    
    public func setSeekToTime(seconds: Double) {
        //不可调节播放进度，会产生回调stop事件
        //        guard let audioFile = self.currentAudioFile else { return }
        //        self.seekStatus = true
        //        self.player.stop()
        //        let sampleRate = audioFile.fileFormat.sampleRate
        //        //播放文件
        //        let startingFrame :AVAudioFramePosition = AVAudioFramePosition(seconds * sampleRate)
        //        skipFrame = startingFrame
        //        // 要根据总时长和当前进度，找出起始的frame位置和剩余的frame数量
        //        let frameCount : AVAudioFrameCount = AVAudioFrameCount(audioFile.length - startingFrame)
        //        // 指定开始播放的音频帧和播放的帧数
        //        player.scheduleSegment(audioFile, startingFrame: startingFrame, frameCount: frameCount, at: nil) {
        //            //            用定时器回调结束
        //            //            if !self.seekStatus {
        //            //                self.playEventsBlock?(.Ended)
        //            //            }
        //        }
        //        self.seekStatus = false
        //        self.player.play()
        
    }
    
    public func resume(isSystemControls: Bool) {
    //恢复播放，那么引擎必须处于运行状态，如果被`stop`，那么调用失败
        if self.engine.isRunning {
            self.player.play()
        } else {
            startEndine()
            self.player.play()
            print("enging not running")
        }
        status = .Playing(0)
    }
    
    public func pause(isSystemControls: Bool) {
        status = .Pause
        self.player.pause()
    }
    
    public func stop() {
        status = .Ended
        self.engine.stop()
        self.player.stop()
        //
        displayLink?.isPaused = true
    }
    
    public func stop(_ issue: Bool) {
        
    }
}
