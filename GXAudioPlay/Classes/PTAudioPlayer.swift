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
    
    public var status : PTAudioPlayerEvent = .None
    
    public var disposeBag = DisposeBag()
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
    
    public var timeEvent: Bool = false {
        didSet {
            if timeEvent {
                addPeriodicTimer()
            } else {
                removePeriodicTimer()
            }
        }
    }
    
    // 播放进度监听
    private var _time_observer: Any? = nil

    public var startTime: Date = Date()
    
    public var playbackDuration: Double = 0
    
    //获取audio时长
    public var duration: Double {
        get {
            if let audioPlayer = remoteAudioPlayer {
                return CMTimeGetSeconds(audioPlayer.currentItem?.duration ?? CMTime.zero)
            }
            return 0
        }
    }
    
    public override init() {
        super.init()
        self.remoteAudioPlayer = AVPlayer()
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
                        
                        if let error = playerItem.error as? NSError {
                            let nsError = NSError(domain: error.domain, code: error.code)
                            self.status = PTAudioPlayerEvent.Error(nsError)
                            self.playEventsBlock?(PTAudioPlayerEvent.Error(nsError))
                        } else {
                            let nsError = NSError(domain: "AVPlayer.failed-\(String(describing: playerItem.error))", code: -1000)
                            self.playEventsBlock?(PTAudioPlayerEvent.Error(nsError))
                            //                            print("AVPlayer.error--\(String(describing: playerItem.error))")
                        }
                        print("AVPlayer.error--\(String(describing: playerItem.error))")
                        try? AVAudioSession.sharedInstance().setActive(false)
                    }
                }
            }).disposed(by: self.disposeBag)
        
        // 缓冲不足暂停
        playerItem.rx.observe(Bool.self, "playbackBufferEmpty").subscribe(onNext: { [weak self] (value) in
            guard let `self` = self else {return}
            if case .Playing = self.status  {
                self.status = PTAudioPlayerEvent.Waiting
//                self.playEventsBlock?(PTAudioPlayerEvent.Waiting)
            }
        }).disposed(by: self.disposeBag)
        
        //缓冲可以播放
        playerItem.rx.observe(Bool.self, "playbackLikelyToKeepUp").subscribe(onNext: { [weak self] (value) in
            guard let `self` = self else {return}
            if  case .Waiting = self.status  {
                self.status = PTAudioPlayerEvent.Playing(0)
                self.remoteAudioPlayer?.play()
                self.remoteAudioPlayer?.rate = self.playSpeed
//                self.playEventsBlock?(PTAudioPlayerEvent.Playing(self.duration))
            }
        }).disposed(by: self.disposeBag)
        

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
        
        //添加音频会话通知监听
        NotificationCenter.default.rx.notification(.AVCaptureSessionRuntimeError).subscribe { [weak self] notic in
            guard let self else { return }
            handleCaptureSessionError(notic)
        }.disposed(by: self.disposeBag)
        
        handleAudioSessionNotification()
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
        if notification.object is AVPlayerItem {
            // 可以在这里检查当前缓冲区状态
            self.playEventsBlock?(.LogError("playbackStalled：播放暂停，可能是缓冲不足"))
        }
    }
    
    @objc private func handleFailedToPlayToEndTime(_ nof:Notification) {
        if let error = nof.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            let errorStr = "failedToPlayToEndTime：\(error.localizedDescription)"
            print(errorStr)
            self.status = PTAudioPlayerEvent.Error(error)
            self.playEventsBlock?(self.status)
        } else {
            //            let errorStr = "failedToPlayToEndTime：未知错误"
            //            print(errorStr)
            //            self.status = PTAudioPlayerEvent.Error(errorStr)
            //            self.playEventsBlock?(self.status)
        }
    }
}

//MARK: - GXAudioPlayerProtocol
extension PTAudioPlayer: GXAudioPlayerProtocol {
    
    public func play(url: String) throws {
        
        let audioUrl =  url.encodeLocalOrRemoteForUrl
        
        guard let audioUrl else {
            throw NSError(domain: "url error", code: -1)
        }
        
        if self.remoteAudioPlayer == nil {
            self.remoteAudioPlayer = AVPlayer.init()
        }
        status = PTAudioPlayerEvent.None
        let playerItem = AVPlayerItem.init(url: audioUrl)
        self.remoteAudioPlayer?.replaceCurrentItem(with: playerItem)
        self.remoteAudioPlayer?.automaticallyWaitsToMinimizeStalling = false
        self.addNotificationRX(playerItem: playerItem)
        startTime = Date()
    }
    
    /// 暂停播放
    public func pause(isSystemControls: Bool = false) {
        remoteAudioPlayer?.pause()
        if isSystemControls {
            self.playEventsBlock?(PTAudioPlayerEvent.Pause)
        } else {
            self.status = .Pause
        }
    }
    
    /// 重新播放
    public func resume(isSystemControls: Bool = false){
        remoteAudioPlayer?.rate = self.playSpeed
        if isSystemControls {
            self.playEventsBlock?(.Playing(self.duration))
        } else {
            self.status = .Playing(0)
        }
    }
    
    public func setSeekToTime(seconds: Double)  {
        // 拖动改变播放进度
        let targetTime: CMTime = CMTimeMake(value: Int64(seconds), timescale: 1)
        //播放器定位到对应的位置
        self.remoteAudioPlayer?.seek(to: targetTime)
    }
//    
    public func stop() {
        stop(false)
    }
    
    /// 停止播放
    public func stop(_ issue : Bool = false) {
        NotificationCenter.default.removeObserver(self)
        self.removePeriodicTimer()
        logPlaybackDuration()
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
