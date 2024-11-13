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
    
    var play: PTAudioPlayer?
    
    /// Play pause control button
    @IBOutlet weak var audioControlBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        play = PTAudioPlayer()
        
        addAVPlayerEvent()
    }
    
    //
    func addAVPlayerEvent() {
        play?.playEventsBlock = { event in
            print(event)
        }
    }
    
    @IBAction func 播放本地音频(_ sender: Any) {
//        guard let url = Bundle.main.url(forResource: "666", withExtension: "wav") else { return }
//        play?.play(url: url)
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
        play?.volume = 1.0
        play?.playSpeed = 1.5
        play?.play(url: "https://file.risekid.cn/book/165/2/1/1.mp3")
        audioControlBtn.setTitle("暂停播放", for: .normal)
    }
    
    @IBAction func 暂停音频(_ sender: Any) {
        
        if play?.isPlaying == true {
            play?.pause()
            audioControlBtn.setTitle("恢复播放", for: .normal)
        } else {
            play?.volume = 1.0
            play?.playSpeed = 1.5
            play?.resume()
            audioControlBtn.setTitle("暂停播放", for: .normal)
        }
        
    }
    
    @IBAction func 停止音频(_ sender: Any) {
        play?.play(url: "https://file.risekid.cn/web/adventure/static/voice_107_1.624644f1.mp3")
        play?.stop()
    }
}
