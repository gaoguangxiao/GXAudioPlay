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
//import PKHUD
import RxSwift
//import FileKit

import GGXSwiftExtension

public enum PTAudioPlayerEvent: Equatable {
    case None
    case isReadyToPlay //URL到准备播放的状态
    case Playing(Double)         // 在媒体开始播放时触发（不论是初次播放、在暂停后恢复、或是在结束后重新开始）
    case TimeUpdate(Double)
    case Waiting         //在一个待执行的操作（如回放）因等待另一个操作（如跳跃或下载）被延迟时触发
    case Pause
    case Ended
    case LoopEndSingle   //单次循环结束
    case Error(String)
}


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
    //self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
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
    
    /// 播放本地音频
    ///
    /// - Parameter filePath: 本地音频路径
    func play(filePath : String) {
        self.setAVAudioSession()
        do {
            audioPlayer?.delegate = nil
            audioPlayer = try AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: filePath))
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            self.playEventsBlock?(.Playing(audioPlayer?.duration ?? 0))
        } catch {
            self.playEventsBlock?(.Error(error.localizedDescription))
            print("open audio failed!-- \(error)")
        }
    }
    
    /// 播放远程的音频文件
    ///
    /// - Parameter url: 音频文件地址
    
    
    /// 播放本地录音文件
    ///
    /// - Parameter path: path
    /// - Returns: 是否播放成功
    public func playPlayback(path: String) -> Bool {
        setAVAudioSession()
        let _path = path
        if path.isEmpty {
            return false
        }
        do {
            audioPlayer?.delegate = nil
            audioPlayer = try AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: _path))
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
        asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
            guard let `self` = self else {return}
            guard case .None = self.status else {
                print("URL尚未播放完毕\(self.status)")
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
        
            _ = playerItem.rx.observeWeakly(AVPlayer.Status.self, "status").asObservable()
                .subscribe(onNext: {[weak self] (event) in
                    guard let `self` = self else {return}
                    if let status = event {
                        if status == AVPlayer.Status.readyToPlay {
                            self.status = PTAudioPlayerEvent.Playing(0)
                            self.playEventsBlock?(PTAudioPlayerEvent.Playing(self.duration))
                            self.remoteAudioPlayer?.rate = self.playSpeed
                            print("播放器readyToPlay：播放时间：\(Date.getCurrentDateStr("yyyy-MM-dd HH:mm:ss.SSS"))")
                            self.remoteAudioPlayer?.play()
                        } else if status == AVPlayer.Status.failed {
                            self.status = PTAudioPlayerEvent.Error("")
                            self.playEventsBlock?(PTAudioPlayerEvent.Error("AVPlayer.failed--\(String(describing: playerItem.error))"))
                            print("AVPlayer.failed--\(String(describing: playerItem.error))")
                        }
                    }
                }).disposed(by: self.disposeBag)
            
            playerItem.rx.observe(Bool.self, "playbackBufferEmpty").subscribe(onNext: { [weak self] (value) in
                guard let `self` = self else {return}
                if case .Playing = self.status  {
                    self.status = PTAudioPlayerEvent.Waiting
                    self.playEventsBlock?(PTAudioPlayerEvent.Waiting)
                }
            }).disposed(by: self.disposeBag)
            
            playerItem.rx.observe(Bool.self, "playbackLikelyToKeepUp").subscribe(onNext: { [weak self] (value) in
                guard let `self` = self else {return}
                if  case .Waiting = self.status  {
                    self.status = PTAudioPlayerEvent.Playing(0)
                    self.remoteAudioPlayer?.play()
                    print("播放器playbackLikelyToKeepUp：播放时间：\(Date.getCurrentDateStr("yyyy-MM-dd HH:mm:ss.SSS"))")
                    self.playEventsBlock?(PTAudioPlayerEvent.Playing(self.duration))
                }
            }).disposed(by: self.disposeBag)
            
            self.remoteAudioPlayer?.replaceCurrentItem(with: playerItem)
            if #available(iOS 10, *) {
                self.remoteAudioPlayer?.automaticallyWaitsToMinimizeStalling = false
                self.remoteAudioPlayer?.rate = self.playSpeed
            } else {
                self.remoteAudioPlayer?.play()
            }
            
            NotificationCenter.default.rx.notification(Notification.Name.AVPlayerItemDidPlayToEndTime)
                .subscribe(onNext: { [weak self] (notic) in
                    guard let `self` = self else {return}
                    if (notic.object as? AVPlayerItem ?? nil) === playerItem {
                        if self.loop {
                            if let playerItem: AVPlayerItem = notic.object as? AVPlayerItem {
                                playerItem.seek(to: CMTime.zero)
                            }
                        } else {
                            if case .Playing = self.status {
                                print("播放器AVPlayerItemDidPlayToEndTime：播放时间：\(Date.getCurrentDateStr("yyyy-MM-dd HH:mm:ss.SSS"))")
                                self.setSeekToTime(seconds: 0)
//                                self.stop(true)
                            }
                        }
                    }
                }).disposed(by: self.disposeBag)
            
            NotificationCenter.default.rx.notification(Notification.Name.AVPlayerItemFailedToPlayToEndTime)
                .subscribe(onNext: { [weak self] (notic) in
                    guard let `self` = self else {return}
                    if (notic.object as? AVPlayerItem ?? nil) === playerItem {
                        if case .Playing = self.status {
                            self.status = PTAudioPlayerEvent.Error("")
                            self.playEventsBlock?(PTAudioPlayerEvent.Error("item has failed to play to its end time -" + (playerItem.error?.localizedDescription ?? "")))
                            self.stop(false)
                        }
                    }
                }).disposed(by: self.disposeBag)
            
            
            NotificationCenter.default.rx.notification(Notification.Name.AVPlayerItemPlaybackStalled)
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

//            NotificationCenter.default.rx.notification(AVAudioSession.RouteChangeReason)
//                .subscribe(onNext: { [weak self] (notic) in
//                    guard let `self` = self else {return}
//                    if (notic.userInfo?[AVAudioSessionRouteChangeReasonKey] as? Int ?? kAudioSessionRouteChangeReason_Unknown) == kAudioSessionRouteChangeReason_OldDeviceUnavailable {
//                        if case .Playing = self.status , self.remoteAudioPlayer?.currentItem?.status == .readyToPlay , self.remoteAudioPlayer?.rate == 0.0 {
//                            self.remoteAudioPlayer?.rate = self.playSpeed
////                            self.remoteAudioPlayer?.play()
//                        }
//                    }
//                }).disposed(by: self.disposeBag)
        }
    }
    
    /// 播放离线包中的缓存
    ///
    /// - Parameter url: url
    /// - Returns: 是否播放成功
//    private func playLocalCache(url: String) -> Bool {
//        var canUseCache = false
//        let resourceID = PTHybridUtil.resourceID(url)
//        if PTHybridCache.share.containResource(resourceID) , let cacheData = PTHybridCache.share.readResourceData(resourceID) {
//            do {
//                audioPlayer?.delegate = nil
//                audioPlayer = try AVAudioPlayer.init(data: cacheData)
//                audioPlayer?.delegate = self
//                audioPlayer?.enableRate = true
//                audioPlayer?.rate = self.playSpeed
//                if  audioPlayer?.prepareToPlay() ?? false {
//                    canUseCache = true
//                    self.remoteAudioPlayer = nil
//                    audioPlayer?.play()
//                    self.status = .Playing(0)
//                    self.playEventsBlock?(.Playing(self.duration))
//                }
//            } catch {
//                PTLog("open audio failed!-- \(error)")
//            }
//        } else {
//            PTHybridManager.share.checkAndDownloadAudioResource(url: url)
//        }
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
    
    func receviedEventEnterBackground() {
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

extension PTAudioPlayer {
    func setAVAudioSession() {
        if AVAudioSession.sharedInstance().category != AVAudioSession.Category.playAndRecord  {
            do {
                if #available(iOS 10.0, *) {//iOS 新增.allowAirPlay .allowBluetoothA2DP
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
                } else {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
                }
                
            } catch {
                
            }
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            
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
        
        //
        if url == self._remoteAudioUrl {
            //相同URL-播放状态
            print("播放状态:\(self.status)-\(self)播放时间：\(Date.getCurrentDateStr("yyyy-MM-dd HH:mm:ss.SSS"))")
//            if self.status == .None { //空闲状态
//                    //如果不是结束
//                print("此URL尚未结束")、
//                self.setSeekToTime(seconds: 0)
//            播放结束改为0
                self.remoteAudioPlayer?.play()
                return
//            }
        }
        
        status = PTAudioPlayerEvent.None
        self._remoteAudioUrl = url
//        let canUseCache = self.playLocalCache(url: url)
//        if canUseCache {
//            var trackDetail : [String : Any] = [:]
//            trackDetail["url"] = url
//            trackDetail["hit"] = 1
//            PTTracker.track(event: "interrupt", attributes: trackDetail)
//        } else {
        if let url = url.toFileUrl {
                if self.remoteAudioPlayer == nil {
                    self.remoteAudioPlayer = AVPlayer.init()
                } else {
//                    self.disposeBag = DisposeBag()
                }
            
            
//            self.status = .isReadyToPlay
//                remoteAudioPlayer?.pause()
                self.playRemoteAudio(url: url)
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
//        NotificationCenter.default.removeObserver(self)
//        self.removePeriodicTimer()
        if issue {
            self.playEventsBlock?(.Ended)
        }
        self.status = .None
        
        //replaceCurrentItem不置为空，如果有同样URL
//        remoteAudioPlayer?.pause()
//        remoteAudioPlayer?.replaceCurrentItem(with: nil)
//        self.remoteAudioPlayer = nil
        
        audioPlayer?.stop()
        self.audioPlayer?.delegate = nil
        self.audioPlayer = nil
        self.playEventsBlock = nil
//        self.disposeBag = DisposeBag()
    }
}
