//
//  GXAudioEnginePlayer.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/11/6.
// 

import Foundation
import AVFoundation

public protocol GXAudioEnginePlayerDelegate: NSObjectProtocol {
    //播放结束，手动停止，或者播放完毕
    func engineDidFinishPlaying(_ player: GXAudioEnginePlayer)
}

public class GXAudioEnginePlayer: NSObject {
    
    private let engine = AVAudioEngine()//音频引擎
    private let player = AVAudioPlayerNode() //播放节点
    
    public weak var delegateEngine : GXAudioEnginePlayerDelegate?
    
    var skipFrame : AVAudioFramePosition = 0//用于记录从某帧开始播放
    
    public override init() {
        //添加播放节点
        engine.attach(player)
        //链接播放节点到引擎的`maxinMixerNode`
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        //预先准备资源
        engine.prepare()
        //打开引擎开关
        try! engine.start()
        
        //默认为0
        skipFrame = 0
        
        //设置音量
        player.volume = 1.0
        //播放速率
        player.rate = 1.0
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
    
    public var currentTime: Double {
        guard let playerTime = currentPlayTime else {
            return 0
        }
        return Double(playerTime.sampleTime + skipFrame)/playerTime.sampleRate
    }
    
    //本地URL
    public func play(fileURL fileUrl: URL) {
        guard let audioFile = try? AVAudioFile(forReading: fileUrl) else { return }
//        player.stop()
        player.scheduleFile(audioFile, at: nil) {
            self.delegateEngine?.engineDidFinishPlaying(self)
        }
        skipFrame = 0
        play()
    }
    
    public func play(fileURL fileUrl: URL,time:Double) {
        guard let audioFile = try? AVAudioFile(forReading: fileUrl) else { return }
        let sampleRate = audioFile.fileFormat.sampleRate
        //播放文件
        let startingFrame :AVAudioFramePosition = AVAudioFramePosition(time * sampleRate)
        skipFrame = startingFrame
        // 要根据总时长和当前进度，找出起始的frame位置和剩余的frame数量
        let frameCount : AVAudioFrameCount = AVAudioFrameCount(audioFile.length - startingFrame)
        // 指定开始播放的音频帧和播放的帧数
        player.scheduleSegment(audioFile, startingFrame: startingFrame, frameCount: frameCount, at: nil, completionHandler: nil)
        play()
    }
    
    /// URL 用PCM缓存播放
    /// - Parameter fileUrl: fileUrl description
    public func playpcm(fileURL fileUrl: URL) {
        guard let audioFile = try? AVAudioFile(forReading: fileUrl) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else { return }
        try? audioFile.read(into: buffer)
        skipFrame = 0
        player.scheduleBuffer(buffer) {
            self.delegateEngine?.engineDidFinishPlaying(self)
        }
        play()
    }
    
    public func playpcm(fileURL fileUrl: URL,options:AVAudioPlayerNodeBufferOptions) {
        guard let audioFile = try? AVAudioFile(forReading: fileUrl) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else { return }
        try? audioFile.read(into: buffer)
        skipFrame = 0
        player.scheduleBuffer(buffer, at: nil,options: options) {
            self.delegateEngine?.engineDidFinishPlaying(self)
        }
    }
    
    /// URL 用PCM缓存播放
    /// - Parameter fileUrl: <#fileUrl description#>
    public func plays(fileURL fileUrls: Array<URL>) {
        for s in fileUrls {
            guard let audioFile = try? AVAudioFile(forReading: s) else { return }
            player.scheduleFile(audioFile, at: nil) {
                self.delegateEngine?.engineDidFinishPlaying(self)
            }
            play()
        }
    }
    
//    -- MARK：功能键
    public func pause(){
        //        self.engine.stop()
        self.player.pause()
    }
    
    public func play() {
        startEndine()
        self.player.play()
    }
    
    //延迟多久播放
    func play(time:AVAudioTime) {
        startEndine()
        self.player.play(at: time)
    }
    
    public func startEndine(){
        if !self.engine.isRunning {
            self.engine.prepare()
            try? self.engine.start()
        }
    }
    
    public func stop() {
        self.engine.stop()
        self.player.stop()
    }
    
    deinit {
        print("dealloc--\(self)")
    }
}
