//
//  AVPlayerViewController.swift
//  GXAudioPlay_Example
//
//  Created by 高广校 on 2023/11/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import GXAudioPlay

class AVPlayerViewController: UIViewController {
    
    private var _audioPlayerMap: [String: PTAudioPlayer] = [:]
    
    @IBOutlet weak var rateText: UILabel!
    @IBOutlet weak var audioTrackText: UILabel!
    
    
    @IBOutlet weak var seekTimeTextField: UITextField!
    
    @IBOutlet weak var playSlider: UISlider!
    
//    var audioPlayer: PTAudioPlayer? {
//        return self._audioPlayerMap["1"]
//    }
    
    //本地音频
    lazy var filePath: URL = {
        let path = Bundle.main.path(forResource: "music-Loop", ofType: "mp3")
        if let uurl = path?.toFileUrl {
            return uurl
        }
        return URL(fileURLWithPath: "")
    }()
    //    let a1 = AVPlayer()
//    let a2 = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self._audioPlayerMap["1"] = PTAudioPlayer()
//        self._audioPlayerMap["2"] = PTAudioPlayer(trackForName: "2")
        
        
    }
    
    @IBAction func 播放音频(_ sender: Any) {
        let audioPlayer = self._audioPlayerMap["1"]
        if  self._audioPlayerMap["1"] != nil {
            audioPlayer?.stop()
        } else {
            self._audioPlayerMap["1"] = audioPlayer
        }
        audioPlayer?.playRemoteAudio(url: filePath)
        audioPlayer?.addPeriodicTimer()
        audioPlayer?.playEventsBlock = { event in
            switch event {
            case .Ended:
                print("播放结束")
                break
            case .Playing(let duration):
                print("音频时长\(duration)")
                DispatchQueue.main.async {
                    self.playSlider.minimumValue = 0
                    self.playSlider.maximumValue = Float(duration)
                }
            case .TimeUpdate(let currentTime):
                let str = "音轨名字：" + "播放时间" + "\(currentTime)"
                self.audioTrackText.text = str
                self.playSlider.value = Float(currentTime)
                break
                
            default: break
                
            }
        }

//        audioPlayer?.play(url: "http://192.168.50.165:8081/static/music-Loop.mp3")
//        audioPlayer?.play(url: "http://192.168.50.165:8081/static/question.fccbbee5.mp3")
        
    }
    
    @IBAction func 播放网络音频(_ sender: Any) {
        let audioPlayer = self._audioPlayerMap["1"]
        if  self._audioPlayerMap["1"] != nil {
            audioPlayer?.stop()
        } else {
            self._audioPlayerMap["1"] = audioPlayer
        }
        let url = "http://192.168.50.165:8081/static/music-Loop.mp3"
        audioPlayer?.play(url: url)
        audioPlayer?.addPeriodicTimer()
        audioPlayer?.playEventsBlock = { event in
            switch event {
            case .Ended:
                print("播放结束")
                break
            case .Playing(let duration):
                print("音频时长\(duration)")
                DispatchQueue.main.async {
                    self.playSlider.minimumValue = 0
                    self.playSlider.maximumValue = Float(duration)
                }
            case .TimeUpdate(let currentTime):
                let str = "音轨名字：" + "播放时间" + "\(currentTime)"
                self.audioTrackText.text = str
                self.playSlider.value = Float(currentTime)
                break
                
            default: break
                
            }
        }
    }
    
    @IBAction func 调节速率(_ sender: UISlider) {
        rateText.text =  "播放速率：" + "\(sender.value)"
        let audioPlayer = self._audioPlayerMap["1"]
//        audioPlayer?.playSpeed = sender.value

    }
    
    @IBAction func 调节播放时间(_ sender: UISlider) {
//        audioPlayer
        print("滑块的值\(sender.value)")
        let audioPlayer = self._audioPlayerMap["1"]
        audioPlayer?.setSeekToTime(seconds: Double(sender.value))
    }
    
    @IBAction func 暂停音频(_ sender: Any) {
        let audioPlayer = self._audioPlayerMap["1"]
        audioPlayer?.pause()
    }
    
    @IBAction func 恢复播放(_ sender: Any) {
        let audioPlayer = self._audioPlayerMap["1"]
        audioPlayer?.resume()
    }
    
    @IBAction func 音频时长(_ sender: Any) {
    
//        print("音频时长\(audioPlayer?.duration)")
//        audioPlayer.duration
    }
    
    @IBAction func 停止音频(_ sender: Any) {
        let audioPlayer = self._audioPlayerMap["1"]
        audioPlayer?.stop()
    }
    
    @IBAction func 循环播放(_ sender: Any) {
        let audioPlayer = self._audioPlayerMap["1"]
        if  self._audioPlayerMap["1"] != nil {
            audioPlayer?.stop()
        } else {
            self._audioPlayerMap["1"] = audioPlayer
        }
//        let url = "http://192.168.50.165:8081/static/music-Loop.mp3"
//        audioPlayer?.play(url: url)
        let url = "http://192.168.50.165:8081/static/music-Loop.mp3"
        audioPlayer?.playRemoteAudio(url: filePath)
        
        audioPlayer?.loop = true
        audioPlayer?.addPeriodicTimer()
        audioPlayer?.playEventsBlock = { event in
            switch event {
            case .Ended:
                print("播放结束")
                break
            case .Playing(let duration):
                print("音频时长\(duration)")
                DispatchQueue.main.async {
                    self.playSlider.minimumValue = 0
                    self.playSlider.maximumValue = Float(duration)
                }
            case .TimeUpdate(let currentTime):
                let str = "音轨名字：" + "播放时间" + "\(currentTime)"
                self.audioTrackText.text = str
                self.playSlider.value = Float(currentTime)
                break
                
            default: break
                
            }
        }
    }
    
    
    @IBAction func 跳过时间(_ sender: Any) {
        //默认第一音轨
        let audioPlayer = self._audioPlayerMap["1"]
//        audioPlayer.
    }
    
    @IBAction func 播放两次(_ sender: Any) {
        let audioPlayer = self._audioPlayerMap["1"]
        if  self._audioPlayerMap["1"] != nil {
            audioPlayer?.stop()
        } else {
            self._audioPlayerMap["1"] = audioPlayer
        }
//        audioPlayer?.playSpeed = 1.2
//        audioPlayer?.loopCount  = 2
        audioPlayer?.play(url: "http://192.168.50.165:8081/static/question.fccbbee5.mp3")
    }
    
    @IBAction func 循环播放之后播第二条(_ sender: Any) {

    }
    
    //显示音轨信息
    func loopOneTrackInfo(event: PTAudioPlayerEvent,audioPlayer:PTAudioPlayer?) {
        switch event {
        case .Ended:
            self.startPlayOneAudioFile()
            break
        case .Playing(let duration):
//            print("音频时长\(curentTiem)")
            DispatchQueue.main.async {
                self.playSlider.minimumValue = 0
                self.playSlider.maximumValue = Float(duration)
            }
        case .TimeUpdate(let currentTime):
            let str = "音轨名字：" + "播放时间" + "\(currentTime)"
            self.audioTrackText.text = str
            playSlider.value = Float(currentTime)
            break
            
        default: break
            
        }
    }
    
//    实现第一条循环播放，需要结束事件
//    第二条在第一条第二次循环时插入播放
    func startPlayOneAudioFile() {
        let audioPlayer = self._audioPlayerMap["1"]
        audioPlayer?.play(url: "http://192.168.50.165:8081/static/music-Loop.mp3")
        audioPlayer?.addPeriodicTimer()
        audioPlayer?.playEventsBlock = { event in
            self.loopOneTrackInfo(event: event,audioPlayer: audioPlayer)
        }
        //打印第二次的回调
//        print(audioPlayer?.playEventsBlock)
    }
    
    func startPlayTwoAudioFile() {
        let audioPlayer = self._audioPlayerMap["2"]
        audioPlayer?.play(url: "http://192.168.50.165:8081/static/music-end.mp3")
        
    }
    
    //显示音轨信息
    func updateTrackInfo(event: GXAudioAVPlayerEvent,audioPlayer:GXAudioAVPlayer?) {
        switch event {
        case .Ended:
            break
        case .TimeUpdate(let currentTime):
            let str = "音轨名字：" + "\(audioPlayer?.trackName ?? "")" + "播放时间" + "\(currentTime)"
            self.audioTrackText.text = str
            break
            
        default: break
            
        }
    }
    
    
}

