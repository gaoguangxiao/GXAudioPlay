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
    
    public var status: PTAudioPlayerEvent = .None
        
    public var disposeBag = DisposeBag()
    
    public var track: String?
    
    public var playSpeed: Float = 1.0
    
    public var volume: Float = 1.0
    
    public var loop: Bool = false
    
    public var numberOfLoops: Int = 0
    
    public  var playEventsBlock: ((PTAudioPlayerEvent) -> ())?
    
//    public var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var startTime: Date?
    
    public func play(url: String) throws {
        
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
//            isPlaying = true
            handleAudioSessionNotification()
            audioPlayer?.play()
        } catch {
            print("Error: Failed to initialize AVAudioPlayer. \(error.localizedDescription)")
            throw error
        }        
    }
    
    /// Stops the currently playing audio.
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
        audioPlayer?.pause()
        self.disposeBag = DisposeBag()
    }
    

    // MARK: - Public Methods

    /// Pauses the currently playing audio.
    public func pause(isSystemControls: Bool = false) {
        if let audioPlayer {
            audioPlayer.pause()
//            logPlaybackDuration()
            if isSystemControls {
                self.playEventsBlock?(PTAudioPlayerEvent.Pause)
            } else {
                self.status = .Pause
            }
            print("Audio playback paused.")
        } else {
            print("No audio is currently playing to pause.")
        }
    }
    
    /// Resumes the currently paused audio.
    public func resume(isSystemControls: Bool = false) {
        if let audioPlayer {
//            startTime = Date()
            audioPlayer.play()
            audioPlayer.rate = self.playSpeed
            audioPlayer.volume = self.volume
            if isSystemControls {
                self.playEventsBlock?(.Playing(audioPlayer.duration))
            } else {
                self.status = .Playing(0)
            }
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

    // MARK: - Private Methods

    /// Logs the duration of audio playback.
    private func logPlaybackDuration() {
        if let startTime = startTime {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("Audio playback duration: \(duration) seconds")
            self.startTime = nil
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AVAudioPlayerService: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        logPlaybackDuration()
//        isPlaying = false
        stop(true)
//        print("Audio finished playing. Success: \(flag)")
//        self.playEventsBlock?(.Ended)
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error {
            self.playEventsBlock?(.Error(error as NSError))
        }
    }
}
