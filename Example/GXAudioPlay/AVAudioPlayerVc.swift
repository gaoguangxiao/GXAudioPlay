//
//  AVAudioPlayerVc.swift
//  GXAudioPlay_Example
//
//  Created by 高广校 on 2023/11/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//  流播放-URL

import UIKit


class AVAudioPlayerVc: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //加载
        //创建上下文对象
//        `unsafeBitCast`：通过变量获取变量内容作为指针,可以很方便得到对象的堆空间地址
//        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
//// 这里传入self，unsafeBitCast函数可以拿到这个变量的内容，并赋值给`context`，设置的类型是`UnsafeMutableRawPointer`
//        
//        // 创建一个活跃的音频文件流解析器，创建解析器 ID
//        let osstatus = AudioFileStreamOpen(context,
//                                           ParserPropertyChangeCallback,
//                                           packetsProc,
//                                           0,
//                                           &_audioFileStreamID)
//        
//        let urlsession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
//        
//        if let url = URL(string: "http://localhost:8081/static/music-Loop.mp3") {
//            let task = urlsession.dataTask(with:url)
//            task.resume()
//        }

        
    }
}
