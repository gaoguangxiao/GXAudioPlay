//
//  AVAudioPlayerVc+Streamer.swift
//  GXAudioPlay_Example
//
//  Created by 高广校 on 2023/12/5.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import GXAudioPlay
import os.log

extension AVAudioPlayerVc: StreamingDelegate {
    
    func streamer(_ streamer: Streaming, failedDownloadWithError error: Error, forURL url: URL) {
        os_log("%@ - %d [%@]", log: AVAudioPlayerVc.logger, type: .debug, #function, #line, error.localizedDescription)
        
        let alert = UIAlertController(title: "Download Failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        show(alert, sender: self)
    }
    
    func streamer(_ streamer: Streaming, updatedDownloadProgress progress: Float, forURL url: URL) {
        os_log("%@ - %d [%.2f]", log: AVAudioPlayerVc.logger, type: .debug, #function, #line, progress)
        
//        progressSlider.progressb = progress
    }
    
    func streamer(_ streamer: Streaming, changedState state: StreamingState) {
        os_log("%@ - %d [%@]", log: AVAudioPlayerVc.logger, type: .debug, #function, #line, String(describing: state))
        
//        switch state {
//        case .playing:
//            playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
//        case .paused, .stopped:
//            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
//        }
    }
    
    func streamer(_ streamer: Streaming, updatedCurrentTime currentTime: TimeInterval) {
//        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, currentTime.toMMSS())
//        
//        if !isSeeking {
//            progressSlider.value = Float(currentTime)
//            currentTimeLabel.text = currentTime.toMMSS()
//        }
//        show(mediaInfo: currentTime)
    }
    
    func streamer(_ streamer: Streaming, updatedDuration duration: TimeInterval) {
//        let formattedDuration = duration.toMMSS()
//        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, formattedDuration)
//        
//        durationTimeLabel.text = formattedDuration
//        durationTimeLabel.isEnabled = true
//        playButton.isEnabled = true
//        progressSlider.isEnabled = true
//        progressSlider.minimumValue = 0.0
//        progressSlider.maximumValue = Float(duration)
        
//        lebngth = duration
    }
    
    
    
    
    override func remoteControlReceived(with event: UIEvent?) {
        guard let e = event else{
            return
        }
        
        
        if e.type == UIEvent.EventType.remoteControl{
            switch e.subtype{
            case UIEvent.EventSubtype.remoteControlPlay:
                streamer.play()
            case UIEvent.EventSubtype.remoteControlPause:
                streamer.pause()
            case UIEvent.EventSubtype.remoteControlNextTrack:
                ()
            case UIEvent.EventSubtype.remoteControlPreviousTrack:
                ()
            default:
                print("There is an issue with the control")
            }
        }


    }
}


