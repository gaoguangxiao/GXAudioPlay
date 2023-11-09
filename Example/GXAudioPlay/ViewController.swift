//
//  ViewController.swift
//  GXAudioPlay
//
//  Created by 小修 on 11/06/2023.
//  Copyright (c) 2023 小修. All rights reserved.
//

import UIKit
import GXAudioPlay
import GGXSwiftExtension
class ViewController: UIViewController {

    var play: GXAudioEnginePlayer?
    
    lazy var url: URL = {
        let path = Bundle.main.path(forResource: "02.Ellis - Clear My Head (Radio Edit) [NCS]", ofType: "mp3")
        if let uurl = path?.toFileUrl {
            return uurl
        }
        return URL(fileURLWithPath: "")
    }()
    
    lazy var url1: URL = {
        let path = Bundle.main.path(forResource: "1", ofType: "wav")
        if let uurl = path?.toFileUrl {
            return uurl
        }
        return URL(fileURLWithPath: "")
    }()
    
    lazy var url2: URL = {
        let path = Bundle.main.path(forResource: "7", ofType: "wav")
        if let uurl = path?.toFileUrl {
            return uurl
        }
        return URL(fileURLWithPath: "")
    }()
    
    lazy var url3: URL = {
        let path = Bundle.main.path(forResource: "2", ofType: "wav")
        if let uurl = path?.toFileUrl {
            return uurl
        }
        return URL(fileURLWithPath: "")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        play = GXAudioEnginePlayer()
        play?.delegateEngine = self
    }

    @IBAction func 实例化Engine(_ sender: Any) {
        play = GXAudioEnginePlayer()
        play?.delegateEngine = self
    }
    
    @IBAction func 播放Engine(_ sender: Any) {
        play?.play(fileURL: url)
    }
    
    @IBAction func 从某时刻播放(_ sender: Any) {
        play?.play(fileURL: url, time: 5.0)
    }
    
    @IBAction func 暂停Engine(_ sender: Any) {
        play?.pause()
    }
    
    @IBAction func 停止Engine(_ sender: Any) {
        play?.stop()
        self.play = nil
    }
    
    @IBAction func 继续Engine(_ sender: Any) {
        play?.play()
    }
    
    @IBAction func 获取播放时长(_ sender: Any) {
        print("音频采样帧数\(play?.currentNodeTime)，音频采样时间\(play?.currentTime)")
    }
    
    @IBAction func 播放PCM音频(_ sender: Any) {
        play?.playpcm(fileURL: url1)
    }
    
    @IBAction func 播放PCM中断(_ sender: Any) {
        //中断其他播放,本次播放完毕，继续播放之前的
        play?.playpcm(fileURL: url2, options: .interrupts)
        
        //等当前播放完毕，再播放本次，本次播放完毕，继续播放本次
//        play?.playpcm(fileURL: url2, options: .loops)
        
        //等当前播放完毕，再播放本次，本次播放完毕，重新播放上次
//        play?.playpcm(fileURL: url2, options: .interruptsAtLoop)
    }
    
    @IBAction func 串行播放(_ sender: Any) {
//        play?.play(fileURL: url1)
//        play?.play(fileURL: url2)
        play?.plays(fileURL: [url1,url2,url3,url2,url1])
    }
    
    
    @IBAction func 混音播放(_ sender: Any) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController : GXAudioEnginePlayerDelegate {
    func engineDidFinishPlaying(_ player: GXAudioEnginePlayer) {
        print("播放结束")
    }
}
