//
//  AVPlayerVc.swift
//  GXAudioPlay_Example
//
//  Created by 高广校 on 2023/11/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//  AVPlayer播放实例

import UIKit
import GXAudioPlay

class AVPlayerVc: UIViewController {
    
    var play: GXAudioPlayerProtocol?
    
    /// Play pause control button
    @IBOutlet weak var audioControlBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        play = PTAudioPlayer()
        play = AVAudioPlayerService()
        
        addAVPlayerEvent()
    }
    
//    var urls = []
    //
    func addAVPlayerEvent() {
        play?.playEventsBlock = { [self] event in
            switch event {
            case .Ended:
                print("播放结束：：：：：")
                //第二次播放
                //                play?.play(fileURL: filePath)
                //                self.startPlayOneAudioFile()
                //                play?.stop()
                
                break
            case .Playing(let duration):
                print("音频时长\(duration)")
                
            case .TimeUpdate(let currentTime):
                break
                
            default: break
                
            }
        }
        
        //        play?.playEventsBlock = { [self] event in
        //                switch event {
        //                case .Ended:
        //                    print("播放结束：：：：：")
        //                    //第二次播放
        //                    play?.play(fileURL: filePath)
        ////                    self.startPlayOneAudioFile()
        //                    break
        //                case .Playing(let duration):
        //        //            print("音频时长\(curentTiem)")
        //                    DispatchQueue.main.async {
        //                        self.playSlider.minimumValue = 0
        //                        self.playSlider.maximumValue = Float(duration)
        //                    }
        //                case .TimeUpdate(let currentTime):
        //                    let str = "音轨名字：" + "播放时间" + "\(currentTime)"
        ////                    self.audioTrackText.text = str
        //                    self.playSlider.value = Float(currentTime)
        //                    break
        //
        //                default: break
        //
        //                }
        //            }
        
        //        play?.delegateEngine = self
    }
    
    @IBAction func 播放本地音频(_ sender: Any) {
        guard let url = Bundle.main.url(forResource: "step.a8e0e8f2", withExtension: "mp3") else {
            print("本地音频文件不存在")
            return
        }
        do {
            try play?.play(url: url.absoluteString)
        } catch  {
            print("播放本地音频 play \(error)")
        }
    }
    
    @IBAction func 播放网络音频(_ sender: Any) {
        
        ///网络音频不存在
        //        play?.play(url: "http://192.168.50.195:4000/static/vo.mp3")
        //        play?.play(url: "https://app.risekid.cn/vo.mp3")
        //    isPlayable: true、isExportable: false
        //        play?.stop()
        //        网络音频不存在
        //        play?.play(url: "https://file.risekid.cn/web/adventure/static/voice_101_1.624644f1.mp3")
        
        //        play?.stop()
        
        //        let index = arc4random()%3
        //        print("index",index)
        //
        //        let urls: Array<String> = ["https://file.risekid.cn/web/adventure/static/sound_107_1_3.8e1d0145.mp3",
        //                    "https://file.risekid.cn/web/adventure/static/voice_107_1.624644f1.mp3",
        //                    "https://file.risekid.cn/web/adventure/static/click.c7752adb.mp3"
        //        ]
        //
        //        //网络音频存在
        //        play?.play(url: urls[Int(index)])
        //
        //        addAVPlayerEvent()
        //        play = PTAudioPlayer()
        
//        progressAction = "";
//        speed = "0.7";
//        timeEvent = 0;
//        track = problem;
//        url = "https://qa3.risekid.cn/static/sound_203_3.5cbdfaf2.mp3";
//        volume = 1;
        play?.volume = 1.0
//        play?.playSpeed = 0.7
        ////        try? play?.play(url: "https://file.risekid.cn/book/165/2/1/1.mp3")
        ///
        do {
            try play?.play(url: "ttps://qa3.risekid.cn/static/sound_203_3.5cbdfaf2.mp3")
        } catch  {
            print("play \(error)")
        }
        //        try?
        //        audioControlBtn.setTitle("暂停播放", for: .normal)
        
                startTimer()
    }
    
    func startTimer() {
        // 定时每隔0.5秒执行一次
        timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(playAudio), userInfo: nil, repeats: true)
    }
    
    @objc func playAudio() {
        do {
            try play?.play(url: "https://file.risekid.cn/web/adventure/static/step.a8e0e8f2.mp3")
        } catch {
            print("play error: \(error)")
        }
    }
    
    var timer: Timer?
    
    @IBAction func 暂停音频(_ sender: Any) {
        
        if play?.isPlaying == true {
            play?.pause(isSystemControls: false)
            audioControlBtn.setTitle("恢复播放", for: .normal)
        } else {
            play?.volume = 1.0
            play?.playSpeed = 1.5
            play?.resume(isSystemControls: false)
            audioControlBtn.setTitle("暂停播放", for: .normal)
        }
        
    }
    
    @IBAction func 停止音频(_ sender: Any) {
        try? play?.play(url: "https://file.risekid.cn/web/adventure/static/voice_107_1.624644f1.mp3")
        play?.stop()
    }
}
