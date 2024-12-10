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
    
    @IBOutlet weak var playSlider: UISlider!
    lazy var url: URL = {
        let path = Bundle.main.path(forResource: "Loop", ofType: "mp3")
        
        if let uurl = path?.toFileUrl {
            return uurl
        }
        
        //        let path = "http://192.168.50.165:8081/static/music-Loop.mp3"
        //        if let uurl = path.toUrl {
        //            return uurl
        //        }
        return URL(fileURLWithPath: "")
    }()
    
    //本地URL
    lazy var filePath: String = {
        let path = Bundle.main.path(forResource: "music-end", ofType: "mp3")
//        if let uurl = path?.toFileUrl {
//            return uurl
//        }
        return path ?? ""
    }()
    
    
    lazy var urlend: URL = {
        let path = Bundle.main.path(forResource: "music-end", ofType: "mp3")
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
    
    @IBAction func 实例化Engine(_ sender: Any) {
        play = GXAudioEnginePlayer()
        //        play?.delegateEngine = self
    }
    
    @IBAction func 播放Engine(_ sender: Any) {
        try? play?.play(url: filePath)
    }
    
    @IBAction func 从某时刻播放(_ sender: Any) {
        play?.play(fileURL: url, time: 110.0)
    }
    
    @IBAction func 暂停Engine(_ sender: Any) {
        play?.pause()
    }
    
    @IBAction func 停止Engine(_ sender: Any) {
        play?.stop()
        self.play = nil
    }
    
    @IBAction func 继续Engine(_ sender: Any) {
        try? play?.resume()
    }
    
    @IBAction func 调节播放时间(_ sender: UISlider) {
        play?.setSeekToTime(seconds: Double(sender.value))
    }
    
    @IBAction func 获取播放时长(_ sender: Any) {
        print("音频采样帧数\(play?.currentNodeTime)，音频采样时间\(play?.currentTime)")
    }
    
    @IBAction func 播放PCM音频(_ sender: Any) {
//        play?.playpcm(fileURL: url1)
        
        play?.playpcmLoop(fileURL: url1)
    }
    
    @IBAction func 播放PCM中断(_ sender: Any) {
        //中断其他播放,本次播放完毕，继续播放之前的
//        play?.playpcm(fileURL: url2, options: .interrupts)
        
        //等当前播放完毕，再播放本次，本次播放完毕，继续播放本次
//        play?.playpcm(fileURL: url2, options: .loops)
        
        //等当前播放完毕，再播放本次，本次播放完毕，重新播放上次
//        play?.playpcm(fileURL: url2, options: .interruptsAtLoop)
        
//        play?.playEndAudio(fileURL: urlend)
    }
    
    @IBAction func 串行播放(_ sender: Any) {
        //        play?.play(fileURL: url1)
        //        play?.play(fileURL: url2)
        play?.plays(fileURL: [url1,url2,url3,url2,url1])
    }
    
    
    @IBAction func 混音播放(_ sender: Any) {
    }
    
    @IBAction func 循环播放(_ sender: Any) {
        play?.playEventsBlock = { [self] event in
            switch event {
            case .Ended:
                print("循环播放结束：：：：：")
                //第二次播放
                play?.playpcm(fileURL: url)
//                play?.play(url: filePath)
                break
            case .Playing(let duration):
                print("音频时长\(duration)")
                DispatchQueue.main.async {
                    self.playSlider.minimumValue = 0
                    self.playSlider.maximumValue = Float(duration)
                }
                
            case .LoopEndSingle:
                //播放尾音
                break
//                play?.playEndAudio(fileURL: urlend)
            case .TimeUpdate(let currentTime):
                let str = "音轨名字：" + "播放时间" + "\(currentTime)"
                //                    self.audioTrackText.text = str
                self.playSlider.value = Float(currentTime)
                break
                
            default: break
                
            }
        }
//        play?.playpcm(fileURL: url1, options: .loops) // 
        play?.loop = true
//        play?.playpcm(fileURL: url)
        try? play?.play(url: filePath)
        //传入插入尾音
        
        //
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loopPlay() {
        play?.play(fileURL: url, time: 0)
    }
    
}

//extension ViewController : GXAudioEnginePlayerDelegate {
//    func engineDidFinishPlaying(_ player: GXAudioEnginePlayer) {
//        print("播放结束")
////        self.loopPlay()
//    }
//}
