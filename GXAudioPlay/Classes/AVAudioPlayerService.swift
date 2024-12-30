//
//  AVAudioPlayerService.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2024/12/17.
//

import Foundation
import AVFoundation
import RxSwift

/// A utility class to manage audio playback using AVAudioPlayer.
public class AVAudioPlayerService: NSObject, GXAudioPlayerProtocol {
    
    public var track: String = ""
    
    public var audioPath: String = ""
    
    public var isRunning: Bool = false
    
    public var canPlayResultTime: Double = 1
    
    public var playingEndTime: Double = 0
    
    public var currentPlayCount: Double = 0
    
    public var status: PTAudioPlayerEvent = .None
    
    public var disposeBag = DisposeBag()
        
    public var playSpeed: Float = 1.0
    
    public var volume: Float = 1.0
    
    public var loop: Bool = false
    
    public var numberOfLoops: Int = 0
    
    public  var playEventsBlock: ((PTAudioPlayerEvent) -> ())?
    
    private var audioPlayer: AVAudioPlayer?
    
    //当前播放进度
    public var currentTime:Double { audioPlayer?.currentTime ?? 0}
    
    //音频时长
    public var duration: Double { audioPlayer?.duration ?? 0 }
    
    public var startTime: Date = Date()
    
    public var playbackDuration: Double = 0
    
    public var timeEvent: Bool = false {
        didSet {
            if timeEvent {
                addPeriodicTimer()
            } else {
                removePeriodicTimer()
            }
        }
    }
    
    public var isLaunchOverTimer: Bool = false
    
    public var canPlayCount: Int = 1
    
    public var overTimer: Timer?
    
    public var canPlayResult: Bool = false
    
    // MARK: - Private Methods
    private var progressTimer: Timer?
    // add Periodic timer
    public func addPeriodicTimer () {
        self.removePeriodicTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.1), repeats: true) { [weak self] t in
            guard let self else {
                return
            }
            // 在这里更新 UI 或执行其他操作
            if let audioPlayer = self.audioPlayer {
                let progress = audioPlayer.currentTime
                //let duration = audioPlayer.duration
                guard case .Playing = self.status else {
                    return
                }
                playEventsBlock?(PTAudioPlayerEvent.TimeUpdate(progress))
            }
        }
        if !Thread.isMainThread {
            if let progressTimer {
                RunLoop.current.add(progressTimer, forMode: .common)
                RunLoop.current.run()
            }
        }
    }
    
    public func removePeriodicTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - Public Methods
    public func replay(url: String) throws {
        
        let audioUrl =  url.encodeLocalOrRemoteForUrl
        
        guard let audioUrl else {
            throw NSError(domain: "url error", code: -1)
        }
        
        canPlayCount -= 1
        audioPath = url
        isLaunchOverTimer = false
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = loop ? -1 : 0
            audioPlayer?.enableRate = true  // Enable rate adjustment
            audioPlayer?.rate = playSpeed  // Set the playback rate
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            startTime = Date()
            status = .Playing(0)
            handleAudioSessionNotification()
            if let b = audioPlayer?.play(), b {
                if !loop {
                    //没有开启循环
                    initOverTimer(overDuration: (duration/Double(self.playSpeed)) + 5,canPlay: true)
                }
            } else {
                throw NSError(domain: "not play", code: -1)
            }
        } catch {
            print("Error: Failed to initialize AVAudioPlayer. \(error.localizedDescription)")
            throw error
        }
    }
    
    public func play(url: String) throws {
        canPlayCount = 2
        try replay(url: url)
        
    }
    
    /// Stops the currently playing audio.
    public func stop() {
        stop(false)
    }
    
    /// Stops the currently playing audio.
    public func stop(_ issue : Bool = false) {
        NotificationCenter.default.removeObserver(self)
        //elf.removePeriodicTimer()
        if issue {
            self.playEventsBlock?(.Ended)
        }
        self.status = .None
        audioPlayer?.pause()
        audioPlayer = nil
        self.disposeBag = DisposeBag()
        removeOverTimer()
    }
    
    /// Pauses the currently playing audio.
    public func pause(isSystemControls: Bool = false) {
        if let audioPlayer {
            audioPlayer.pause()
            //            logPlaybackDuration()
            if isSystemControls {
//                self.playEventsBlock?(PTAudioPlayerEvent.Pause)
            } else {
                self.status = .Pause
            }
            print("Audio playback paused.")
            pauseOverTimer()
        } else {
            print("No audio is currently playing to pause.")
        }
    }
    
    /// Resumes the currently paused audio.
    public func resume(isSystemControls: Bool = false) {
        if let audioPlayer {
            audioPlayer.rate = self.playSpeed
            audioPlayer.volume = self.volume
            audioPlayer.play()
            if isSystemControls {
//                self.playEventsBlock?(.Playing(audioPlayer.duration))
            } else {
                self.status = .Playing(0)
            }
            resumeOverTimer()
            print("Audio playback resumed.")
        } else {
            print("No paused audio to resume.")
        }
    }
    
    /// Adjusts the playback volume.
    /// - Parameter volume: The volume level (0.0 to 1.0).
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
        print("Volume set to \(volume).")
    }
    
    /// Adjusts the playback rate.
    /// - Parameter rate: The playback speed (e.g., 1.0 for normal speed, 2.0 for double speed).
    func setRate(_ rate: Float) {
        if let audioPlayer = audioPlayer, audioPlayer.enableRate {
            audioPlayer.rate = rate
            print("Playback rate set to \(rate).")
        } else {
            print("Rate adjustment is not supported.")
        }
    }
    
    public func setSeekToTime(seconds: Double) {
        if let audioPlayer {
            // 设置音频开始播放的时间
            audioPlayer.currentTime = seconds
            // 播放音频
            audioPlayer.play()
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AVAudioPlayerService: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("audioPlayerDidFinishPlaying:\(flag)")
        logPlaybackDuration()
        stop(true)
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("audioPlayerDecodeErrorDidOccur:\(error)")
        if let error {
            self.playEventsBlock?(.Error(error as NSError))
        }
        stop(false)
    }
    
    public func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
//        print("audioPlayerBeginInterruption:\(track)")
    }
    
    public func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
//        print("audioPlayerEndInterruption:\(track)、flags:\(flags)")
    }
}
