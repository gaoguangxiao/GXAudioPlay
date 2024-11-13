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
class AVAudioEngineVc: UIViewController {
    
    var play: GXAudioPlayerProtocol?
    
    @IBOutlet weak var playSlider: UISlider!
    
    @IBOutlet weak var engineStatus: UILabel! //引擎状态
    
    lazy var url: String = {
        if let path = Bundle.main.path(forResource: "click.c7752adb", ofType: "mp3") {
            return path
        }
        
        //        if let uurl = path?.toFileUrl {
        //            return uurl
        //        }
        
        //        let path = "http://192.168.50.165:8081/static/music-Loop.mp3"
        //        if let uurl = path.toUrl {
        //            return uurl
        //        }
        return ""
    }()
    
    //本地URL
    lazy var filePath: String = {
        let path = Bundle.main.path(forResource: "Loop", ofType: "mp3")
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
        let path = Bundle.main.path(forResource: "2024-10-22_15-20-44", ofType: "mp3")
        if let uurl = path?.toFileUrl {
            return uurl
        }
        return URL(fileURLWithPath: "")
    }()
    
    public var bridgeRespTimes: Dictionary<Int, Double> = [:]
    public var callbackId: Int = 0
    
    var readTime: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        play = GXAudioEnginePlayer()
        if let play {
            addAVPlayerEvent(play: play)
        }
//        play?.playEventsBlock = { [weak self] event in
//            guard let self else { return  }
//            DispatchQueue.main.async {
//                switch event {
//                case .Ended:
////                    print("播放结束：：：：：")
//                    self.isPlaying = false
//                    self.engineStatus.text = "无"
//                    if let startReceiveTime = self.bridgeRespTimes[self.callbackId] {
//                        let timeInterval = CFAbsoluteTimeGetCurrent() - startReceiveTime
//                        print("`\(callbackId)`的响应时间: \(timeInterval * 1000)毫秒")
//                        if let self.readTime {
//                            let timeIntervalV2 = (timeInterval - readTime) * 1000
//                            print("非播放时间： \(timeIntervalV2)毫秒")
//                        }
//                        //停止
//    //                    timer?.invalidate()
//    //                    timer = nil
//                    }
//                    break
//                case .Playing(let duration):
//                    print("音频时长\(duration)")
//                    DispatchQueue.main.async {
//                        self.readTime = duration
//                        self.playSlider.minimumValue = 0
//                        self.playSlider.maximumValue = Float(duration)
//                    }
//                    
//                case .TimeUpdate(let currentTime):
//                    let str = "音轨名字：" + "播放时间" + "\(currentTime)"
//                    //                    self.audioTrackText.text = str
//                    self.playSlider.value = Float(currentTime)
//                    break
//                    
//                case .Error(let errorstr):
//                    self.isPlaying = false
//                    self.engineStatus.text = "无"
//                default: break
//                    
//                }
//            }
//            
//        }
        
        //        play?.delegateEngine = self
    }
    
    func addAVPlayerEvent(play: GXAudioPlayerProtocol) {
        play.playEventsBlock = { [weak self] event in
            guard let self else { return  }

            switch event {
            case .Ended :
                if let startReceiveTime = self.bridgeRespTimes[self.callbackId] {
                    let timeInterval = CFAbsoluteTimeGetCurrent() - startReceiveTime
                    
                    print("`\(callbackId)`的响应时间: \(timeInterval * 1000)毫秒")
                    if let readTime {
                        let timeIntervalV2 = (timeInterval - readTime) * 1000
                        print("非播放时间： \(timeIntervalV2)毫秒")
                    }
                    
                    //停止
//                    timer?.invalidate()
//                    timer = nil
                }
                break
            case .None:
                break
            case .Playing(let duation):
                readTime = duation
                break
            case .TimeUpdate(_):
                break
            case .Waiting:
                break
            case .Pause:
                break
            case .Interruption:
                break
            case .LoopEndSingle:
                break
            case .Error(_):
                break
            }
//            if event == .Ended {
//                if let startReceiveTime = self.bridgeRespTimes[self.callbackId] {
//                    let timeInterval = CFAbsoluteTimeGetCurrent() - startReceiveTime
//
//                    let timeIntervalV2 = CFAbsoluteTimeGetCurrent() - (play. ?? 0)
//
//                    print("`\(callbackId)`的响应时间: \(timeInterval * 1000)毫秒、\(timeIntervalV2)")
//                }
//            } else if event == .Playing()
        }
    }
    
    @IBAction func 实例化Engine(_ sender: Any) {
        play = GXAudioEnginePlayer()
        //        play?.delegateEngine = self
    }
    
    @IBAction func 播放Engine(_ sender: Any) {
        let path = Bundle.main.path(forResource: "1", ofType: "wav")
        play?.play(url: url)
        
        bridgeRespTimes[callbackId] = play?.startPlayTime
        isPlaying = true
        self.engineStatus.text = "播放"
    }
    
    @IBAction func 从某时刻播放(_ sender: Any) {
        //        play?.play(fileURL: url, time: 110.0)
    }
    
    var isPlaying = false
    @IBAction func 暂停Engine(_ sender: Any) {
        
        if isPlaying {
            play?.pause()
            isPlaying = false
            self.engineStatus.text = "暂停"
        } else {
            play?.resume()
            isPlaying = true
            self.engineStatus.text = "播放中"
        }
    }
    
    @IBAction func 停止Engine(_ sender: Any) {
        play?.stop(false)
        self.play = nil
    }
    
    //    @IBAction func 继续Engine(_ sender: Any) {
    //        play?.resume()
    //    }
    
    @IBAction func 调节播放时间(_ sender: UISlider) {
        play?.setSeekToTime(seconds: Double(sender.value))
    }
    
    @IBAction func 获取播放时长(_ sender: Any) {
//        print("音频采样帧数\(play?.currentNodeTime)，音频采样时间\(play?.currentTime)")
    }
    
    @IBAction func 播放PCM音频(_ sender: Any) {
//        play?.playpcm(fileURL: url1)
        
        //        play?.playpcmLoop(fileURL: url1)
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
//        play?.plays(fileURL: [url1,url2,url3,url2,url1])
    }
    
    
    @IBAction func 混音播放(_ sender: Any) {
    }
    
    @IBAction func 循环播放(_ sender: Any) {
        play?.playEventsBlock = { [self] event in
            switch event {
            case .Ended:
                print("循环播放结束：：：：：")
                //第二次播放
                //                play?.playpcm(fileURL: url)
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
        play?.play(url: filePath)
        //传入插入尾音
        
        //
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loopPlay() {
        //        play?.play(fileURL: url, time: 0)
    }
    
}

//extension ViewController : GXAudioEnginePlayerDelegate {
//    func engineDidFinishPlaying(_ player: GXAudioEnginePlayer) {
//        print("播放结束")
////        self.loopPlay()
//    }
//}
