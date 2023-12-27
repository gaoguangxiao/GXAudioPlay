//
//  AVAudioPlayerVc.swift
//  GXAudioPlay_Example
//
//  Created by 高广校 on 2023/11/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//  流播放-URL

import UIKit
import GXAudioPlay
import AVFAudio
import os.log

class AVAudioPlayerVc: UIViewController {
    
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Streamer")
    
    var parser: Parser?
    public internal(set) var reader_ha: Reading?
    
    public var readFormat: AVAudioFormat {
        AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: true)!
    }
    
    //  buffer size , 选用 4 k
    //  采用 32 KB 也可以
    public var readBufferSize: AVAudioFrameCount {
        4096
    }
    
    var intervalD: Double{
        Double(readBufferSize) * 0.5 / readFormat.sampleRate
    }
    
    let play = GXAudioEnginePlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //预加载网络音频
//        if let url = URL(string: "http://localhost:8081/static/music-Loop.mp3") {
//            streamer.url = url
//        }
     
        
    }
    
    @IBAction func 播放本地音频(_ sender: Any) {
        
        guard let url = Bundle.main.url(forResource: "666", withExtension: "wav") else { return }
    }
    
    @IBAction func 播放网络音频(_ sender: Any) {
                
        
        //
        for i in 0..<8 {
            //极短音频
            if let url = URL(string: "http://localhost:8081/static/letter-repeat-down.mp3") {
                streamer.url = url
//                streamer.repeats = true
                streamer.play()
            }
        }
        
//        if streamer.state == .playing {
//            streamer.pause()
//        } else {
//            streamer.play()
//        }
//        let urlsession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
//
//        if let url = URL(string: "http://localhost:8081/static/music-Loop.mp3") {
//            let task = urlsession.dataTask(with:url)
//            task.resume()
//        }

    }
    
    @IBAction func 暂停音频(_ sender: Any) {
    }
    
    lazy var streamer: Streamer = {
        let streamer = Streamer()
        streamer.delegate = self
        return streamer
    }()
    
    
}

extension AVAudioPlayerVc: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let error = error {
            
        } else {
            print("下载完成")
        }
    }
    
}
