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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        play = PTAudioPlayer()
        
        
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
        
        //网络音频存在
        play?.play(url: "https://file.risekid.cn/web/adventure/static/voice_107_1.624644f1.mp3")
        
        addAVPlayerEvent()
    }
    
    @IBAction func 暂停音频(_ sender: Any) {
        play?.pause()
    }
}
