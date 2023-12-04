//
//  GXAudioAVPlayer.swift
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

extension GXAudioAVPlayer: AVAssetResourceLoaderDelegate {
    
}

public class GXAudioAVPlayer: NSObject {
    
    static let shared = GXAudioAVPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    
   
    //当前的网络播放地址
    private var _remoteAudioUrl: String = ""
    
    private var _pauseForEnterBackground: Bool = false
    
    public var trackName: String?
    
    //主播放器
    private var remoteAudioPlayer: AVPlayer?
    //活跃播放进度监听
    private var _main_time_observer: Any? = nil
    
    //创建第二个播放缓冲，用于解决循环播放无间隔问题，成为辅助播放器
    private var remoteRepeatPlayer: AVPlayer?
    //辅助播放进度监听
    private var _time_repeat_observer: Any? = nil
    
    //活跃的AVPlayer，可以被上面 两个播放器赋值，只能存在
    var currentAudioPlayer: AVPlayer?
    //活跃播放进度监听
    private var _time_observer: Any? = nil
    
    
    public var playEventsBlock: ((GXAudioAVPlayerEvent)->())?
    
    var status : GXAudioAVPlayerEvent = .None
    
    private var disposeBag = DisposeBag()
    //播放器速度
    public var playSpeed: Float = 1.0
    //播放器音量
    var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
            currentAudioPlayer?.volume = volume
        }
    }
    
    public var loop: Bool = false {// false 不循环播放  true 循环播放
        didSet {
            if loop {
                //如果开启循环
                self.beginMainAudioTime()
            } else {
//                remoteAudioPlayer?.actionAtItemEnd = .pause
            }
        }
    }


    
    //获取audio时长
    public var duration: Float64 {
        get {
            if let audioPlayer = remoteAudioPlayer {
                let duration = CMTimeGetSeconds(audioPlayer.currentItem?.duration ?? .zero)
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
    
    public init(trackForName name: String) {
        super.init()
        self.trackName = name
        self.remoteAudioPlayer = AVPlayer()
    }
    
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
    public func play(url: String) {
        self.setAVAudioSession()
        status = GXAudioAVPlayerEvent.None
        self._remoteAudioUrl = url
        if let url = URL.init(string: url)  {
            if self.remoteAudioPlayer == nil {
                self.remoteAudioPlayer = AVPlayer.init()
            }
            self.currentAudioPlayer = self.remoteAudioPlayer
            remoteAudioPlayer?.pause()
            self.playRemoteAudio(url: url)
        } else {
            self.playEventsBlock?(GXAudioAVPlayerEvent.Error("url异常：\(url)"))
        }
    }
    
    //开启主控制器播放时间监听
    func beginMainAudioTime() {
        
        if let ob = _main_time_observer {
            self.remoteAudioPlayer?.removeTimeObserver(ob)
            _main_time_observer = nil
        }
        
        _main_time_observer = self.remoteAudioPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.init(label: "audio.interval"), using: {  [weak self] (time) in

            //2、当前播放时间距离结束差2S
            let currentTime = time.seconds
            let aDuration = self?.duration ?? 0
            if currentTime >= aDuration - 2.0 {
                if let url = URL(string: self?._remoteAudioUrl ?? "") {
                    self?.beginRepeatAudio(path: url)
                }
            }
            //3、当前播放时间距离结束差1S
             if currentTime >= aDuration - 1.0 {
                if let avrepeatlayer = self?.remoteRepeatPlayer {
                    //将辅助播放器设置为0
                    avrepeatlayer.currentItem?.seek(to: .zero, completionHandler: { b in
                        if b {
                            //修改当前播放器
                            self?.currentAudioPlayer = avrepeatlayer
                            //主播放器置为0秒 并 置为暂停
                            self?.remoteAudioPlayer?.seek(to: .zero)
                            self?.remoteAudioPlayer?.pause()
                        }
                    })
                }
            }
        })
    }
    
    //开启音频循环播放
    func beginRepeatAudio(path: URL) {
        let playerItem: AVPlayerItem = AVPlayerItem(url: path)
        if self.remoteRepeatPlayer == nil {
            self.remoteRepeatPlayer = AVPlayer()
        }
        
        
        //需要构建自己的`AVPlayerItem`
        self.remoteRepeatPlayer?.replaceCurrentItem(with: playerItem)
        self.remoteRepeatPlayer?.play()
                
        if let ob = _time_repeat_observer {
            self.remoteRepeatPlayer?.removeTimeObserver(ob)
            _time_repeat_observer = nil
        }
        
        _time_repeat_observer = self.remoteRepeatPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.init(label: "audioRepeat.interval"), using: {  [weak self] (time) in
            
            //2、当前播放时间距离结束差2S
            let currentTime = time.seconds
            let aDuration = playerItem.duration.seconds //获取当前播放实例的播放总时长
            if currentTime >= aDuration - 2.0 {
                if let avplayer = self?.remoteAudioPlayer {
                    avplayer.play()
                }
            }
            //3、当前播放时间距离结束差1S
            if currentTime >= aDuration - 1.0 {
                if let avplayer = self?.remoteAudioPlayer {
                    //将辅助播放器设置为0
                    avplayer.currentItem?.seek(to: .zero, completionHandler: { b in
                        if b {
                            //修改当前播放器
                            self?.currentAudioPlayer = avplayer
                            //主播放器置为0秒 并 置为暂停
                            self?.remoteRepeatPlayer?.seek(to: .zero)
                            self?.remoteRepeatPlayer?.pause()
                        }
                    })
                }
            }
            
            //回调 播放时间进度
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                guard case .Playing = self.status else {return}
                self.playEventsBlock?(.TimeUpdate(currentTime))
            }
        })
    }
    
    /// 播放本地录音文件
    ///
    /// - Parameter path: path
    /// - Returns: 是否播放成功
    func playPlayback(path: String) -> Bool {
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
    
    
    private func playRemoteAudio(url : URL) {
        let asset = AVURLAsset.init(url: url)
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        
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
            
            _ = playerItem.rx.observeWeakly(AVPlayer.Status.self, "status").asObservable()
                .subscribe(onNext: {[weak self] (event) in
                    guard let `self` = self else {return}
                    if let status = event {
                        if status == AVPlayer.Status.readyToPlay {
                            self.status = GXAudioAVPlayerEvent.Playing(0)
                            self.playEventsBlock?(GXAudioAVPlayerEvent.Playing(self.duration))
                            self.remoteAudioPlayer?.rate = self.playSpeed
                        } else if status == AVPlayer.Status.failed {
                            self.status = GXAudioAVPlayerEvent.Error("")
                            self.playEventsBlock?(GXAudioAVPlayerEvent.Error("AVPlayer.failed--\(String(describing: playerItem.error))"))
                            print("AVPlayer.failed--\(String(describing: playerItem.error))")
                        }
                    }
                }).disposed(by: self.disposeBag)
            
            playerItem.rx.observe(Bool.self, "playbackBufferEmpty").subscribe(onNext: { [weak self] (value) in
                guard let `self` = self else {return}
                
                if let b = value {
                    self.status = GXAudioAVPlayerEvent.Waiting
                    self.playEventsBlock?(GXAudioAVPlayerEvent.Waiting)
                }
            }).disposed(by: self.disposeBag)
            
            playerItem.rx.observe(Bool.self, "playbackLikelyToKeepUp").subscribe(onNext: { [weak self] (value) in
                guard let `self` = self else {return}
                if let b = value  {
                    self.status = GXAudioAVPlayerEvent.Playing(0)
//                    self.remoteAudioPlayer?.play()
                    self.playEventsBlock?(GXAudioAVPlayerEvent.Playing(self.duration))
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
                                self.stop(true)
                            }
                        }
                    }
                }).disposed(by: self.disposeBag)
            
            NotificationCenter.default.rx.notification(Notification.Name.AVPlayerItemFailedToPlayToEndTime)
                .subscribe(onNext: { [weak self] (notic) in
                    guard let `self` = self else {return}
                    if (notic.object as? AVPlayerItem ?? nil) === playerItem {
                        if case .Playing = self.status {
                            self.status = GXAudioAVPlayerEvent.Error("")
                            self.playEventsBlock?(GXAudioAVPlayerEvent.Error("item has failed to play to its end time -" + (playerItem.error?.localizedDescription ?? "")))
                            self.stop(false)
                        }
                    }
                }).disposed(by: self.disposeBag)
            
            
            NotificationCenter.default.rx.notification(Notification.Name.AVPlayerItemPlaybackStalled)
                .subscribe(onNext: { [weak self] (notic) in
                    guard let `self` = self else {return}
                    if (notic.object as? AVPlayerItem ?? nil) === playerItem {
                        if case .Playing = self.status {
                            self.status = GXAudioAVPlayerEvent.Error("")
                            self.playEventsBlock?(GXAudioAVPlayerEvent.Error("media did not arrive in time to continue playback -" +  (playerItem.error?.localizedDescription ?? "")))
                            self.stop(false)
                        }
                    }
                }).disposed(by: self.disposeBag)
            
        }
    }
    
    /// 播放进度的监听
    public func addPeriodicTimer () {
        
        self.removePeriodicTimer()
        if self.currentAudioPlayer != nil {
            _time_observer = self.currentAudioPlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.init(label: "audio.interval"), using: {  [weak self] (time) in
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    guard case .Playing = self.status else {return}
                    self.playEventsBlock?(.TimeUpdate(time.seconds))
                }
            })
        } else {
//            _time_observer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] (_timer) in
//                guard let `self` = self else {
//                    _timer.invalidate()
//                    return
//                }
//                if case .Ended = self.status {
//                    _timer.invalidate()
//                    return
//                }
//                if self.audioPlayer?.isPlaying ?? false{
//                    self.playEventsBlock?(GXAudioAVPlayerEvent.TimeUpdate(self.audioPlayer?.currentTime ?? 0))
//                }
//            })
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
                self.currentAudioPlayer?.removeTimeObserver(ob)
                _time_observer = nil
            }
        }
    }
    
    func removeAllPeriodicTimer() {
        if let ob = _main_time_observer {
            self.remoteAudioPlayer?.removeTimeObserver(ob)
            _main_time_observer = nil
        }
        
        if let ob = _time_repeat_observer {
            self.remoteRepeatPlayer?.removeTimeObserver(ob)
            _time_repeat_observer = nil
        }
    }
    
    func receviedEventEnterBackground() {
        var needPause = false
        if case .Playing = self.status  { needPause = true }
        if case .Waiting = self.status  { needPause = true }
        if needPause  {
            if self == GXAudioAVPlayer.shared {
                GXAudioAVPlayer.shared.stop(true)
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
    
    /// 停止播放
    public func stop(_ issue : Bool = false) {
        if issue {
            self.playEventsBlock?(.Ended)
        }
    }
    
    deinit {
        audioPlayer?.delegate = nil
        remoteAudioPlayer = nil
        self.stop()
    }
}

extension GXAudioAVPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if loop {
            
        } else {
            player.delegate = nil
            self.stop(true)
        }
    }
}

extension GXAudioAVPlayer {
    
    public func play(fileURL fileUrl: URL) {
        
    }
    
    public func play() {
        
    }
    
    /// 暂停播放
    public func pause() {
        self.playEventsBlock?(GXAudioAVPlayerEvent.Pause)
        self.status = .Pause
        audioPlayer?.pause()
        currentAudioPlayer?.pause()
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
        currentAudioPlayer?.rate = self.playSpeed
        audioPlayer?.rate = self.playSpeed
    }
    
    /// 停止播放
    public func stop() {
        NotificationCenter.default.removeObserver(self)
        self.removeAllPeriodicTimer()
        
        self.status = .None

        currentAudioPlayer?.pause()
        currentAudioPlayer?.replaceCurrentItem(with: nil)

        audioPlayer?.stop()
        self.audioPlayer?.delegate = nil
        self.audioPlayer = nil
        self.playEventsBlock = nil
        self.disposeBag = DisposeBag()
    }
    
    public func setSeekToTime(seconds: Double)  {
        // 拖动改变播放进度
        let targetTime: CMTime = CMTimeMake(value: Int64(seconds), timescale: 1)
        //播放器定位到对应的位置
        self.currentAudioPlayer?.seek(to: targetTime)
    }
}

extension GXAudioAVPlayer {
    func setAVAudioSession() {
        if AVAudioSession.sharedInstance().category != AVAudioSession.Category.playAndRecord  {
            setAudioAndRecordingCategory()
        }
        setAVAudioSessionActive()
    }
    
    func setAudioAndRecordingCategory() {
        do {
            if #available(iOS 10.0, *) {//iOS 新增.allowAirPlay .allowBluetoothA2DP
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            }
            
        } catch let error {
            
        }
    }
    
    func setAVAudioSessionActive() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            
        }
    }
    
}
