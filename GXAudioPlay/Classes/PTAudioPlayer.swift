//
//  PTAudioPlayer.swift
//  KidReading
//
//  Created by zoe on 2019/8/20.
//  Copyright © 2019 putao. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia
import RxCocoa
import RxSwift

public class PTAudioPlayer: NSObject {
    
    public static let shared = PTAudioPlayer()
    
    /// An instance object of AVPlayer
    private var remoteAudioPlayer: AVPlayer?
    
    public var playEventsBlock: ((PTAudioPlayerEvent)->())?
    
    var status : PTAudioPlayerEvent = .None
    
    private var disposeBag = DisposeBag()
    //播放器速度
    public var playSpeed: Float = 1.0
    //播放器音量
    public var volume: Float = 1.0 {
        didSet {
            remoteAudioPlayer?.volume = volume
        }
    }
    public var loop: Bool = false {// false 不循环播放  true 循环播放
        didSet {
            if loop {
                remoteAudioPlayer?.actionAtItemEnd = .none
            } else {
                remoteAudioPlayer?.actionAtItemEnd = .pause
            }
        }
    }
    
    ///The default number of current cycles is 0
    private var currentNumberOfLoops: Int = 0
    
    public var numberOfLoops: Int = 1 {
        didSet {
            //reset to 0
            currentNumberOfLoops = 0
            remoteAudioPlayer?.actionAtItemEnd = .none
        }
    }
    
    public var track: String?
    
    // 播放进度监听
    private var _time_observer: Any? = nil
    //当前的网络播放地址
    private var _remoteAudioUrl: String = ""
    
    private var _pauseForEnterBackground: Bool = false
    
    
    //获取audio时长
    private var duration: Double {
        get {
            if let audioPlayer = remoteAudioPlayer {
                //                let timeRange = audioPlayer.currentItem?.loadedTimeRanges.first?.timeRangeValue
                let duration = CMTimeGetSeconds(audioPlayer.currentItem?.duration ?? CMTime.zero)
                return duration
            }
            return 0
        }
    }
    
    /// 是否正在播放
    public var isPlaying: Bool {
        get {
            if case .Playing = self.status {
                return true
            }
            return false
        }
    }
    
    public override init() {
        super.init()
        self.remoteAudioPlayer = AVPlayer()
        print("init----")
    }
    
    func configureAudioSessionForPlayback() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // 设置音频会话为播放模式，不涉及录音
//            try audioSession.setCategory(.playback, options: [
//                .allowBluetooth,     // 如果允许通过蓝牙播放
//                .allowAirPlay        // 如果允许通过 AirPlay 播放
//            ])
            try audioSession.setCategory(.playback, mode: .default)
            // 激活音频会话
            try audioSession.setActive(true)
            print("AVAudioSession 已激活为 playback 模式")
        } catch {
            print("configureAudioSessionForPlayback 配置 AVAudioSession 失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    func addNotificationRX(playerItem: AVPlayerItem) {
        
        playerItem.rx.observeWeakly(AVPlayer.Status.self, "status").asObservable()
            .subscribe(onNext: {[weak self] (event) in
                guard let `self` = self else { return }
                if let status = event {
                    if status == AVPlayer.Status.readyToPlay {
                        self.status = PTAudioPlayerEvent.Playing(0)
                        self.playEventsBlock?(PTAudioPlayerEvent.Playing(self.duration))
                        self.remoteAudioPlayer?.play()
                        self.remoteAudioPlayer?.rate = self.playSpeed
                    } else if status == AVPlayer.Status.failed {
                        stop(false)
                        self.status = PTAudioPlayerEvent.Error("")
                        self.playEventsBlock?(PTAudioPlayerEvent.Error("AVPlayer.failed--\(String(describing: playerItem.error))"))
                        print("AVPlayer.error--\(String(describing: playerItem.error))")
                        try? AVAudioSession.sharedInstance().setActive(false)
                        try? configureAudioSessionForPlayback()
                        
                    }
                }
            }).disposed(by: self.disposeBag)
        
        // 缓冲不足暂停
        playerItem.rx.observe(Bool.self, "playbackBufferEmpty").subscribe(onNext: { [weak self] (value) in
            guard let `self` = self else {return}
            if case .Playing = self.status  {
                self.status = PTAudioPlayerEvent.Waiting
                self.playEventsBlock?(PTAudioPlayerEvent.Waiting)
            }
        }).disposed(by: self.disposeBag)
        
        //缓冲可以播放
        playerItem.rx.observe(Bool.self, "playbackLikelyToKeepUp").subscribe(onNext: { [weak self] (value) in
            guard let `self` = self else {return}
            if  case .Waiting = self.status  {
                self.status = PTAudioPlayerEvent.Playing(0)
                self.remoteAudioPlayer?.play()
                self.remoteAudioPlayer?.rate = self.playSpeed
                self.playEventsBlock?(PTAudioPlayerEvent.Playing(self.duration))
            }
        }).disposed(by: self.disposeBag)
        
        //        NotificationCenter.default.rx.notification(AVPlayerItem.newErrorLogEntryNotification)
        //            .subscribe(onNext: { (notic) in
        //                print("newErrorLogEntryNotification")
        //            }).disposed(by: self.disposeBag)
        //
        //        NotificationCenter.default.rx.notification(AVPlayerItem.failedToPlayToEndTimeNotification)
        //            .subscribe(onNext: { (notic) in
        //                print("failedToPlayToEndTimeNotification")
        //            }).disposed(by: self.disposeBag)
        
        self.remoteAudioPlayer?.replaceCurrentItem(with: playerItem)
        self.remoteAudioPlayer?.automaticallyWaitsToMinimizeStalling = false
        self.remoteAudioPlayer?.rate = self.playSpeed
        
        NotificationCenter.default.rx.notification(AVPlayerItem.didPlayToEndTimeNotification)
            .subscribe(onNext: { [weak self] (notic) in
                guard let self else {return}
                if (notic.object as? AVPlayerItem ?? nil) === playerItem {
                    if self.loop {
                        //无限循环
                        guard numberOfLoops != 0 else {
                            if let playerItem: AVPlayerItem = notic.object as? AVPlayerItem {
                                playerItem.seek(to: CMTime.zero)
                            }
                            return
                        }
                        //有次数的循环 0 1 2 end 3
                        currentNumberOfLoops += 1
                        guard currentNumberOfLoops < numberOfLoops else {
                            if case .Playing = self.status {
                                self.stop(true)
                            }
                            return
                        }
                        if let playerItem: AVPlayerItem = notic.object as? AVPlayerItem {
                            playerItem.seek(to: CMTime.zero)
                        }
                    } else {
                        if case .Playing = self.status {
                            self.stop(true)
                        }
                    }
                }
            }).disposed(by: self.disposeBag)
        
        //        当 AVPlayerItem 未能播放到结尾时触发。
        NotificationCenter.default.rx.notification(AVPlayerItem.failedToPlayToEndTimeNotification)
            .subscribe(onNext: { [weak self] (notic) in
                guard let self else { return }
                handleFailedToPlayToEndTime(notic)
            }).disposed(by: self.disposeBag)
        
        //当播放器生成新的错误日志条目时触发。错误日志提供关于播放问题的更多信息。
        NotificationCenter.default.rx.notification(AVPlayerItem.newErrorLogEntryNotification)
            .subscribe(onNext: { [weak self] (notic) in
                guard let self else { return }
                handleErrorLog(notic)
            }).disposed(by: self.disposeBag)
        
        //播放器在播放过程中遇到问题，无法继续流畅播放，播放停滞时触发-旧版认为错误，新版将日志上报
        NotificationCenter.default.rx.notification(AVPlayerItem.playbackStalledNotification)
            .subscribe(onNext: { [weak self] (notic) in
                guard let self else { return }
                handlePlaybackStalled(notic)
            }).disposed(by: self.disposeBag)
        
        // 播放器被中断
        NotificationCenter.default.rx.notification(AVAudioSession.interruptionNotification).subscribe(onNext: { [weak self] (notic) in
            guard let self else { return }
            interruptionTypeChanged(notic)
        }).disposed(by: self.disposeBag)
        
        //添加音频会话通知监听
        NotificationCenter.default.rx.notification(.AVCaptureSessionRuntimeError).subscribe { [weak self] notic in
            guard let self else { return }
            handleCaptureSessionError(notic)
        }.disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(AVAudioSession.routeChangeNotification).subscribe { [weak self] notic in
            guard let self else { return }
            routeChangeTyptChanged(notic)
        }.disposed(by: self.disposeBag)
    }
    
    /// 播放进度的监听
    public func addPeriodicTimer () {
        
        self.removePeriodicTimer()
        if self.remoteAudioPlayer != nil {
            _time_observer = self.remoteAudioPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.init(label: "audio.interval"), using: { (time) in
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else {return}
                    guard case .Playing = self.status else {return}
                    self.playEventsBlock?(PTAudioPlayerEvent.TimeUpdate(time.seconds))
                }
            })
        }
    }
    
    public func removePeriodicTimer() {
        if let ob = _time_observer {
            if ((ob as? Timer) != nil) {
                var timer = ob as? Timer
                timer?.invalidate()
                timer = nil
                _time_observer = nil
            } else {
                self.remoteAudioPlayer?.removeTimeObserver(ob)
                _time_observer = nil
            }
        }
    }
    
    public func receviedEventEnterBackground() {
        var needPause = false
        if case .Playing = self.status  { needPause = true }
        if case .Waiting = self.status  { needPause = true }
        if needPause  {
            if self == PTAudioPlayer.shared {
                PTAudioPlayer.shared.stop(true)
            } else {
                self._pauseForEnterBackground = true
                self.pause()
            }
        }
    }
    
    func receviedEventEnterForeground() {
        if case .Pause = self.status , self._pauseForEnterBackground == true {
            self._pauseForEnterBackground = false
            try? self.resume()
        } else if case .Playing = self.status  {
            self.stop(true)
        }
    }
    
    ///  Audio session change notification
    func mediaChangeInterruptionType(begin: Bool) {
        if begin {
            receviedEventEnterBackground()
        } else {
            receviedEventEnterForeground()
        }
    }
    
    deinit {
        remoteAudioPlayer = nil
        self.stop()
        print("dealloc--\(self)")
        //        ZKLog("\(self) dealloc\(String(describing: remoteAudioPlayer))")
    }
}

/// 音频通知
//MARK: - audio notification
extension PTAudioPlayer {
    
    // 错误音频会话处理函数
    @objc func handleCaptureSessionError(_ nof: Notification) {
        if let error = nof.userInfo?[AVCaptureSessionErrorKey] as? AVError {
            print("Capture session runtime error: \(error.localizedDescription)")
            // 根据错误类型做相应的处理
            self.playEventsBlock?(.LogError("newErrorLogEntry:\(error.localizedDescription)"))
            
            if error.code == .mediaServicesWereReset {
                
            } else {
                
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    // 恢复播放或录制
                } catch {
                    print("无法激活音频会话: \(error.localizedDescription)")
                    self.playEventsBlock?(.LogError("captureSession setActive:\(error.localizedDescription)"))
                }
            }
        }
    }
    
    @objc private func handleErrorLog(_ nof:Notification) {
        //        LogError
        if let playerItem = nof.object as? AVPlayerItem,
           let errorLog = playerItem.errorLog() {
            self.playEventsBlock?(.LogError("newErrorLogEntry:\(errorLog.description)"))
        }
    }
    
    @objc private func handlePlaybackStalled(_ notification: Notification) {
        // 判断具体的播放项（如果有多个 AVPlayerItem）
        if let playerItem = notification.object as? AVPlayerItem {
            // 可以在这里检查当前缓冲区状态
            self.playEventsBlock?(.LogError("playbackStalled：播放暂停，可能是缓冲不足"))
        }
    }
    
    @objc private func handleFailedToPlayToEndTime(_ nof:Notification) {
        if let error = nof.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            let errorStr = "failedToPlayToEndTime：\(error.localizedDescription)"
            print(errorStr)
            self.status = PTAudioPlayerEvent.Error(errorStr)
            self.playEventsBlock?(self.status)
        } else {
            let errorStr = "failedToPlayToEndTime：未知错误"
            print(errorStr)
            self.status = PTAudioPlayerEvent.Error(errorStr)
            self.playEventsBlock?(self.status)
        }
    }
    
    ///打断
    @objc private func interruptionTypeChanged(_ nof:Notification) {
        
        guard let userInfo = nof.userInfo, let reasonValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        
        switch reasonValue {
        case AVAudioSession.InterruptionType.began.rawValue://Began
            var isAnotherAudioSuspend = false //是否是被其他音频会话打断
            if #available(iOS 10.3, *) {
                if #available(iOS 14.5, *) {
                    // iOS 14.5之后使用InterruptionReasonKey
                    let reasonKey = userInfo[AVAudioSessionInterruptionReasonKey] as! UInt
                    switch reasonKey {
                    case AVAudioSession.InterruptionReason.default.rawValue:
                        //因为另一个会话被激活,音频中断
                        isAnotherAudioSuspend = true
                        break
                    case AVAudioSession.InterruptionReason.appWasSuspended.rawValue:
                        //由于APP被系统挂起，音频中断。
                        break
                    case AVAudioSession.InterruptionReason.builtInMicMuted.rawValue:
                        //音频因内置麦克风静音而中断(例如iPad智能关闭套iPad's Smart Folio关闭)
                        break
                    default: break
                    }
                    print("AVAudioSessionInterruption: \(reasonKey)")
                } else {
                    // iOS10.3-14.5，InterruptionWasSuspendedKey为true表示中断是由于系统挂起，false是被另一音频打断
                    let suspendedNumber:NSNumber = userInfo[AVAudioSessionInterruptionWasSuspendedKey] as! NSNumber
                    isAnotherAudioSuspend = !suspendedNumber.boolValue
                }
            }
            
            if isAnotherAudioSuspend {
                //                if (self.delegate != nil){
                mediaChangeInterruptionType(begin: true)
                print("mediaChangeInterruptionType: 开始")
                //                }
            }
            break
        case AVAudioSession.InterruptionType.ended.rawValue://End
            let optionKey = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
            if optionKey == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                //指示另一个音频会话的中断已结束，本应用程序可以恢复音频。
                //                if (self.delegate != nil){
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    // 恢复播放或录制
                } catch {
                    print("无法激活音频会话: \(error.localizedDescription)")
                    self.playEventsBlock?(.LogError("setActive:\(error.localizedDescription)"))
                }
                mediaChangeInterruptionType(begin: false)
                print("mediaChangeInterruptionType: 结束")
                //                }
            }
            break
        default: break
        }
    }
    
    ///耳机
    @objc private func routeChangeTyptChanged(_ nof:Notification) {
        //        print("audio session route change \(nof)")
        
        guard let userInfo = nof.userInfo else { return }
        var seccReason = ""
        guard let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt else {return}
        
        switch reason {
        case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
            seccReason = "有新设备可用"
            // 一般为接入了耳机,参数为旧设备的信息。
            guard let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription  else {
                return
            }
            if previousRoute.inputs.count <= 0 && previousRoute.outputs.count <= 0 {
                return
            }
            
            let previousOutput = previousRoute.outputs[0]
            let portType = previousOutput.portType
            print("音频模式更改:有新设备可用通知- \(portType.rawValue)")
            if portType == AVAudioSession.Port.headphones {
                //在这里暂停播放, 更改输出设备，录音时背景音需要重置。否则无法消音
                print("耳机🎧模式")
            } else if portType == AVAudioSession.Port.builtInSpeaker {
                print("Built-in speaker on an iOS device")
            }
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
            seccReason = "老设备不可用"
            guard let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription  else {
                return
            }
            if previousRoute.inputs.count <= 0 && previousRoute.outputs.count <= 0 {
                return
            }
            let previousOutput = previousRoute.outputs[0]
            let portType = previousOutput.portType
            print("音频模式更改:老设备不可用通知- \(portType.rawValue)")
            if portType == AVAudioSession.Port.headphones {
                print("耳机🎧模式")
                if isPlaying {
                    try? self.resume()
                }
            } else if portType == AVAudioSession.Port.builtInSpeaker {
                
            }
        case AVAudioSession.RouteChangeReason.categoryChange.rawValue:
            seccReason = "类别Cagetory改变了"
        case AVAudioSession.RouteChangeReason.override.rawValue:
            seccReason = "App重置了输出设置"
        case AVAudioSession.RouteChangeReason.wakeFromSleep.rawValue:
            seccReason = "从睡眠状态呼醒"
        case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory.rawValue:
            seccReason = "当前Category下没有合适的设备"
            
        case AVAudioSession.RouteChangeReason.routeConfigurationChange.rawValue:
            seccReason = "Rotuer的配置改变了"
            //        case AVAudioSession.RouteChangeReason.unknown,
        default:
            seccReason = "未知原因"
        }
    }
}

extension PTAudioPlayer: GXAudioPlayerProtocol {
    public func play(url: String) throws {
//        try self.configureAudioSessionForPlayback()
        
        status = PTAudioPlayerEvent.None
        
        let canUseCache = FileManager.default.fileExists(atPath: url)
        var audioUrl: URL?
        if canUseCache {
            var fileUrl : URL?
            if #available(iOS 16.0, *) {
                fileUrl = URL(filePath: url)
            } else {
                // Fallback on earlier versions
                fileUrl = URL(fileURLWithPath: url)
            }
            audioUrl = fileUrl
        } else {
            guard let escapedURLString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                throw NSError(domain: "PercentEncoding.error", code: -1)
            }
            audioUrl = URL(string: escapedURLString)
        }
        
        guard let audioUrl else {
            throw NSError(domain: "url error", code: -1)
        }
        
        self._remoteAudioUrl = url
        if self.remoteAudioPlayer == nil {
            self.remoteAudioPlayer = AVPlayer.init()
        } else {
            //                    self.disposeBag = DisposeBag()
        }
        remoteAudioPlayer?.pause()
        //            self.playRemoteAudio(url: _url)
        let playerItem = AVPlayerItem.init(url: audioUrl)
        self.addNotificationRX(playerItem: playerItem)
        
    }
    
    public func play(fileURL fileUrl: URL) {
        
    }
    
    /// 暂停播放
    public func pause() {
        self.playEventsBlock?(PTAudioPlayerEvent.Pause)
        self.status = .Pause
        remoteAudioPlayer?.pause()
    }
    
    /// 重新播放
    public func resume() throws {
        self.playEventsBlock?(.Playing(self.duration))
        self.status = .Playing(0)
        remoteAudioPlayer?.rate = self.playSpeed
    }
    
    public func setSeekToTime(seconds: Double)  {
        // 拖动改变播放进度
        let targetTime: CMTime = CMTimeMake(value: Int64(seconds), timescale: 1)
        //播放器定位到对应的位置
        self.remoteAudioPlayer?.seek(to: targetTime)
    }
    
    public func stop() {
        stop(false)
    }
    
    /// 停止播放
    public func stop(_ issue : Bool = false) {
        NotificationCenter.default.removeObserver(self)
        self.removePeriodicTimer()
        if issue {
            self.playEventsBlock?(.Ended)
        }
        self.status = .None
        remoteAudioPlayer?.pause()
        remoteAudioPlayer?.replaceCurrentItem(with: nil)
        //        self.remoteAudioPlayer = nil
        self.disposeBag = DisposeBag()
    }
}

extension PTAudioPlayer {
    func getDeviceOutputInfo(portType: AVAudioSession.Port) -> String {
        var type = ""
        switch portType {
        case .headsetMic:
            type = "headsetMic"
        case .builtInMic:
            type = "内置麦克风"
        case .builtInSpeaker:
            type = "内置扬声器"
        case .headphones:
            type = "插线耳机"
        case .bluetoothA2DP:
            type = "蓝牙音频传输模型协议"
        case .bluetoothLE:
            type = "低功耗蓝牙"
        case .airPlay:
            type = "隔空播放"
            
        default:
            type = "内置扬声器"
        }
        return type
    }
}
