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
    //总时长 和 当前播放时长
        let audioTime =  play?.currentNodeTime
        
//        print("音频节点时间\(play?.currentNodeTime)，音频采样播放时间\(play?.currentPlayTime)")
    
//        if let nodeTime = play?.currentTime {
//            print(nodeTime.sampleTime/nodeTime.sampleRate)
//        }
        
        print("音频采样帧数\(play?.currentNodeTime)，音频采样时间\(play?.currentTime)")
//        play?.currentFrame
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
