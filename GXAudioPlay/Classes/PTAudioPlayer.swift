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
    
    private var audioPlayer: AVAudioPlayer?
    //远程服务器的mp3播放需要使用AVPlayer
    private var remoteAudioPlayer: AVPlayer?
    
    //    private var currentItem: AVPlayerItem?
    //
    public var playEventsBlock: ((PTAudioPlayerEvent)->())?
    
    var status : PTAudioPlayerEvent = .None
    
    private var disposeBag = DisposeBag()
    //播放器速度
    public var playSpeed: Float = 1.0
    //播放器音量
    public var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
            remoteAudioPlayer?.volume = volume
        }
    }
    public var loop: Bool = false {// false 不循环播放  true 循环播放
        didSet {
            if loop {
                audioPlayer?.numberOfLoops = -1//零值表示只播放一次声音。值为1将导致声音播放两次，依此类推。任何负数将无限循环，直到停止。
                remoteAudioPlayer?.actionAtItemEnd = .none
            } else {
                audioPlayer?.numberOfLoops = 0//零值表示只播放一次声音。值为1将导致声音播放两次，依此类推。任何负数将无限循环，直到停止。
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
            return audioPlayer?.duration ?? 0
        }
    }
    
    /// 是否正在播放
    var isPlaying: Bool {
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
    }
    //    @objc func playerItemDidReachEnd(notification: NSNotification) {
    //        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
    //            playerItem.seek(to: CMTime.zero)
    //        }
    //    }
    
    /// 播放本地录音文件
    ///
    /// - Parameter path: path
    /// - Returns: 是否播放成功
    public func playPlayback(path: URL) -> Bool {
        //setAVAudioSession()
        if AVAudioSession.sharedInstance().category != AVAudioSession.Category.playback  {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
            } catch {
                return false
            }
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            return false
        }
        let _path = path
        do {
            audioPlayer?.delegate = nil
            audioPlayer = try AVAudioPlayer.init(contentsOf:  _path)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            self.status = .Playing(0)
            self.playEventsBlock?(.Playing(audioPlayer?.duration ?? 0))
            return true
        } catch {
            print("open audio failed!-- \(error)")
            return false
        }
    }
    
    
    public func playRemoteAudio(url : URL) {
        let asset = AVURLAsset.init(url: url)
        
        // Load an asset's list of tracks.
        if #available(iOS 15, *) {
            Task {
                do {
                    //// Load an asset's suitability for playback and export.
                    // let (isPlayable, isExportable) = try await asset.load(.isPlayable, .isExportable)
                    let isPlayable = try await asset.load(.isPlayable)
                    //                    print("isPlayable: \(isPlayable)、isExportable: \(isExportable)")
                    var playerItem = AVPlayerItem.init(url: url)
                    if isPlayable {
                        let status = asset.status(of: .isPlayable)
                        switch status {
                        case .loaded(_):
                            playerItem = AVPlayerItem.init(asset: asset)
                        case .loading:
                            break
                        default:
                            break
                        }
                        self.addNotificationRX(playerItem: playerItem, url: url)
                    } else {
                        self.status = PTAudioPlayerEvent.Error("")
                        self.playEventsBlock?(PTAudioPlayerEvent.Error("AVURLAsset.isPlayable-is :\(isPlayable)"))
                        //                        self.playEventsBlock?(PTAudioPlayerEvent.Error("AVURLAsset.isPlayable-is :\(isPlayable)、AVURLAsset.isExportable-is :\(isExportable)"))
                    }
                } catch let e as NSError {
                    self.status = PTAudioPlayerEvent.Error("")
                    self.playEventsBlock?(PTAudioPlayerEvent.Error("try-catch:\(e.description)"))
                }
            }
        } else {
            // Fallback on earlier versions
            asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
                guard let `self` = self else {return}
                guard case .None = self.status else {
                    return
                }
                var error: NSError? = nil
                var playerItem = AVPlayerItem.init(url: url)
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                
                switch status {
                case .loaded:
                    playerItem = AVPlayerItem.init(asset: asset)
                default:
                    break
                }
                self.addNotificationRX(playerItem: playerItem, url: url)
            }
        }
    }
    
    func addNotificationRX(playerItem: AVPlayerItem,url: URL) {
        
        playerItem.rx.observeWeakly(AVPlayer.Status.self, "status").asObservable()
            .subscribe(onNext: {[weak self] (event) in
                guard let `self` = self else { return }
                if let status = event {
                    if status == AVPlayer.Status.readyToPlay {
                        self.status = PTAudioPlayerEvent.Playing(0)
                        self.playEventsBlock?(PTAudioPlayerEvent.Playing(self.duration))
                        self.remoteAudioPlayer?.rate = self.playSpeed
                    } else if status == AVPlayer.Status.failed {
                        self.status = PTAudioPlayerEvent.Error("")
                        self.playEventsBlock?(PTAudioPlayerEvent.Error("AVPlayer.failed--\(String(describing: playerItem.error))"))
                        print("AVPlayer.failed--\(String(describing: playerItem.error))")
                        print("AVPlayer.error--\(String(describing: url))")
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
        if #available(iOS 10, *) {
            self.remoteAudioPlayer?.automaticallyWaitsToMinimizeStalling = false
            self.remoteAudioPlayer?.rate = self.playSpeed
        } else {
            self.remoteAudioPlayer?.play()
        }
        
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
        
        NotificationCenter.default.rx.notification(AVPlayerItem.failedToPlayToEndTimeNotification)
            .subscribe(onNext: { [weak self] (notic) in
                guard let `self` = self else {return}
                if (notic.object as? AVPlayerItem ?? nil) === playerItem {
                    if case .Playing = self.status {
                        self.stop(true)
                    }
                }
            }).disposed(by: self.disposeBag)
        
        
        NotificationCenter.default.rx.notification(AVPlayerItem.playbackStalledNotification)
            .subscribe(onNext: { [weak self] (notic) in
                guard let `self` = self else {return}
                if (notic.object as? AVPlayerItem ?? nil) === playerItem {
                    if case .Playing = self.status {
                        self.status = PTAudioPlayerEvent.Error("")
                        self.playEventsBlock?(PTAudioPlayerEvent.Error("media did not arrive in time to continue playback -" +  (playerItem.error?.localizedDescription ?? "")))
                        self.stop(false)
                    }
                }
            }).disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(AVAudioSession.interruptionNotification).subscribe(onNext: { [weak self] (notic) in
            guard let self else { return }
            interruptionTypeChanged(notic)
        }).disposed(by: self.disposeBag)
        
        //
        //            NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
        //                .subscribe(onNext: { [weak self] _ in
        //                    guard let self else {return}
        ////                    receviedEventEnterBackground()
        //                }).disposed(by: disposeBag)
        //
        //            NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
        //                .subscribe(onNext: { [weak self] _ in
        //                    guard let self else {return}
        ////                    receviedEventEnterForeground()
        //                }).disposed(by: disposeBag)
        //
        //            NotificationCenter.default.rx.notification(AVAudioSession.RouteChangeReason)
        //                .subscribe(onNext: { [weak self] (notic) in
        //                    guard let `self` = self else {return}
        //                    if (notic.userInfo?[AVAudioSessionRouteChangeReasonKey] as? Int ?? kAudioSessionRouteChangeReason_Unknown) == kAudioSessionRouteChangeReason_OldDeviceUnavailable {
        //                        if case .Playing = self.status , self.remoteAudioPlayer?.currentItem?.status == .readyToPlay , self.remoteAudioPlayer?.rate == 0.0 {
        //                            self.remoteAudioPlayer?.rate = self.playSpeed
        //                            self.remoteAudioPlayer?.play()
        //                        }
        //                    }
        //                }).disposed(by: self.disposeBag)
    }
    /// 播放离线包中的缓存
    ///
    /// - Parameter url: url
    /// - Returns: 是否播放成功
    //    private func playLocalCache(url: String) -> Bool {
    //        var canUseCache = false
    //        //本地文件
    //        canUseCache = FileManager.default.fileExists(atPath: url)
    //        guard canUseCache == true else {
    //            return false
    //        }
    //        var fileUrl : URL?
    //        if #available(iOS 16.0, *) {
    //            fileUrl = URL(filePath: url)
    //        } else {
    //            // Fallback on earlier versions
    //            fileUrl = URL(fileURLWithPath: url)
    //        }
    //        if let fileUrl, let cacheData = try? Data(contentsOf: fileUrl){
    //            do {
    //                audioPlayer?.delegate = nil
    //                audioPlayer = try AVAudioPlayer.init(data: cacheData)
    //                audioPlayer?.delegate = self
    //                audioPlayer?.enableRate = true
    //                audioPlayer?.rate = self.playSpeed
    //
    //                audioPlayer?.prepareToPlay()
    //
    ////                if audioPlayer?.prepareToPlay() ?? false {
    //                    canUseCache = true
    //                    self.remoteAudioPlayer = nil
    //                    audioPlayer?.play()
    //                    self.status = .Playing(0)
    //                    self.playEventsBlock?(.Playing(self.duration))
    ////                } else {
    ////                    canUseCache = false
    ////                    print("prepareToPlay failed!--")
    ////                }
    //            } catch {
    //                print("open audio failed!-- \(error)")
    //            }
    //        } else {
    //            //            self.playEventsBlock?(.Error("URL异常"))
    //            canUseCache = false
    //        }
    //        //        let resourceID = PTHybridUtil.resourceID(url)
    //        //        if PTHybridCache.share.containResource(resourceID) , let cacheData = PTHybridCache.share.readResourceData(resourceID) {
    //        //
    //        //        } else {
    //        //            //PTHybridManager.share.checkAndDownloadAudioResource(url: url)
    //        //        }
    //        return canUseCache
    //    }
    
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
        } else {
            _time_observer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] (_timer) in
                guard let `self` = self else {
                    _timer.invalidate()
                    return
                }
                if case .Ended = self.status {
                    _timer.invalidate()
                    return
                }
                if self.audioPlayer?.isPlaying ?? false{
                    self.playEventsBlock?(PTAudioPlayerEvent.TimeUpdate(self.audioPlayer?.currentTime ?? 0))
                }
            })
        }
    }
    
    //    public func setSeekToTime(seconds: Double)  {
    //        // 拖动改变播放进度
    //        let targetTime: CMTime = CMTimeMake(value: Int64(seconds), timescale: 1)
    //        //播放器定位到对应的位置
    //        self.remoteAudioPlayer?.seek(to: targetTime)
    //    }
    
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
            self.resume()
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
        audioPlayer?.delegate = nil
        remoteAudioPlayer = nil
        self.stop()
        //        ZKLog("\(self) dealloc\(String(describing: remoteAudioPlayer))")
    }
    
    
}

extension PTAudioPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if loop {
            
        } else {
            player.delegate = nil
            self.stop(true)
        }
        
        
        //        self.status = .Ended
        //        self.playEventsBlock?(.Ended)
        
    }
}

/// 音频通知
//MARK: - audio notification
extension PTAudioPlayer {
    
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
                mediaChangeInterruptionType(begin: false)
                print("mediaChangeInterruptionType: 结束")
                //                }
            }
            break
        default: break
        }
    }
}

extension PTAudioPlayer: GXAudioPlayerProtocol {
    
    //    public var loop: Bool = false {// false 不循环播放  true 循环播放
    //        didSet {
    //            if loop {
    //                audioPlayer?.numberOfLoops = -1//零值表示只播放一次声音。值为1将导致声音播放两次，依此类推。任何负数将无限循环，直到停止。
    //                remoteAudioPlayer?.actionAtItemEnd = .none
    //            } else {
    //                audioPlayer?.numberOfLoops = 0//零值表示只播放一次声音。值为1将导致声音播放两次，依此类推。任何负数将无限循环，直到停止。
    //                remoteAudioPlayer?.actionAtItemEnd = .pause
    //            }
    //        }
    //    }
    
    //    public func play(fileURL fileUrl: String) {
    //
    //    }
    
    
    public func play(url: String) {
        self.setAVAudioSession()
        status = PTAudioPlayerEvent.None
        
        //将str
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
                return
            }
            audioUrl = URL(string: escapedURLString)
        }
        
        if let _url = audioUrl {
            self._remoteAudioUrl = url
            if self.remoteAudioPlayer == nil {
                self.remoteAudioPlayer = AVPlayer.init()
            } else {
                //                    self.disposeBag = DisposeBag()
            }
            remoteAudioPlayer?.pause()
            self.playRemoteAudio(url: _url)
        } else {
            self.playEventsBlock?(PTAudioPlayerEvent.Error("url异常：\(url)"))
        }
        //        }
    }
    
    public func play(fileURL fileUrl: URL) {
        
    }
    
    /// 暂停播放
    public func pause() {
        self.playEventsBlock?(PTAudioPlayerEvent.Pause)
        self.status = .Pause
        audioPlayer?.pause()
        remoteAudioPlayer?.pause()
    }
    
    /// 重新播放
    public func resume() {
        if let _audioPlayer = audioPlayer  {
            if _audioPlayer.currentTime == 0 || !_audioPlayer.play() {
                self.stop(true)
                return
            }
        }
        self.playEventsBlock?(.Playing(self.duration))
        self.status = .Playing(0)
        setAVAudioSession()
        remoteAudioPlayer?.rate = self.playSpeed
        audioPlayer?.rate = self.playSpeed
        //        audioPlayer?.volume = self.volume
        //        remoteAudioPlayer?.volume = self.volume
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
        audioPlayer?.stop()
        self.audioPlayer?.delegate = nil
        self.audioPlayer = nil
        self.playEventsBlock = nil
        self.disposeBag = DisposeBag()
    }
}
