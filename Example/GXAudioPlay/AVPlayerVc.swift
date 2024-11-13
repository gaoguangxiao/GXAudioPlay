//
//  AVPlayerVc.swift
//  GXAudioPlay_Example
//
//  Created by 高广校 on 2023/11/29.
//  Copyright © 2023 CocoaPods. All rights reserved.
//  AVPlayer播放实例

import UIKit
import GXAudioPlay
import AVFoundation

class AVPlayerVc: UIViewController {
    
    //
    var play: GXAudioPlayerProtocol?
    
    public var bridgeRespTimes: Dictionary<Int, Double> = [:]
    public var callbackId: Int = 0
    
    /// Play pause control button
    @IBOutlet weak var audioControlBtn: UIButton!
    
    var readTime: Double?
    
    /// timer
    var timer: Timer?
    /// timer count
    var currentTimerCount: Float = 0.01
    
    //记录该次播放状态、
    public var playState: Dictionary<Int, Bool> = [:]
    
    //预置缓冲
    public var cacheItem: Dictionary<Int, AVPlayerItem> = [:]
    
    public var currentItemIndex = 0
    
    @IBOutlet weak var loopSlider: UISwitch! //开启循环
    
    @IBOutlet weak var speedSliderTxt: UILabel!
    @IBOutlet weak var speedSlider: UISlider!//播放速度
    
    @IBOutlet weak var volumeSliderTxt: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!//音量
    
    //音频时长
    var landingAudioDution : Float = 600
    lazy var landingAudio: String = {
        if let path = Bundle.main.path(forResource: "click.c7752adb", ofType: "mp3") {
            return path
        }
        return ""
    }()
    
//    let path = Bundle.main.path(forResource: "2024-10-22_15-20-44", ofType: "mp3")
    let path = Bundle.main.path(forResource: "01.Halcyon - Runaway (Feat. Valentina Franco) (Heuse Remix)", ofType: "mp3")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        play = GXAudioEnginePlayer()
//        play = PTAudioPlayer()
        play?.addPeriodicTimer()
        if let play {
            addAVPlayerEvent(play: play)
        }
        
        if let url = landingAudio.toFileUrl {
            let item1 = AVPlayerItem(url: url)
            cacheItem[0] = item1
        }
        if let url = landingAudio.toFileUrl {
            let item1 = AVPlayerItem(url: url)
            cacheItem[1] = item1
        }
        if let url = landingAudio.toFileUrl {
            let item1 = AVPlayerItem(url: url)
            cacheItem[2] = item1
        }
        if let url = landingAudio.toFileUrl {
            let item1 = AVPlayerItem(url: url)
            cacheItem[3] = item1
        }
    }
    
    @IBAction func VolumeSliderChange(_ sender: UISlider) {
        let str = String(format: "%.2f",sender.value)
        volumeSliderTxt.text = "音量：\(str)"
    }
    
    @IBAction func SpeedSliderChange(_ sender: UISlider) {
//        print("播放速率： \(sender.value)")
        let str = String(format: "%.2f",sender.value)
        speedSliderTxt.text = "播放速率：\(str)"
    }
    
    @IBOutlet weak var playProgress: UIProgressView! //播放进度
    //
    func addAVPlayerEvent(play: GXAudioPlayerProtocol) {
        play.playEventsBlock = { [weak self] event in
            guard let self else { return  }

            switch event {
            case .Ended :
                //                if let startReceiveTime = play.startPlayTime {
                let timeInterval = CFAbsoluteTimeGetCurrent() - play.startPlayTime
                
                print("`\(callbackId)`的响应时间: \(timeInterval * 1000)毫秒")
                if let readTime {
                    let timeIntervalV2 = (timeInterval - readTime) * 1000
                    print("非播放时间： \(timeIntervalV2)毫秒")
                }
                
                //停止
                //                    timer?.invalidate()
                //                    timer = nil
                //                }
                break
            case .None:
                break
            case .Playing(let duation):
                readTime = duation
                break
            case .TimeUpdate(let currentTime):
                print("播放时间： \(currentTime * 1000)毫秒")
                self.playProgress.progress = Float(currentTime/(readTime ?? 1))
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
        }
    }
    
    @IBAction func 播放本地音频(_ sender: Any) {
        play?.loop = self.loopSlider.isOn
        play?.playSpeed = self.speedSlider.value
        play?.numberOfLoops = 0
        play?.volume = self.volumeSlider.value
//        play?.play(url: path ?? "")
        play?.play(url: landingAudio)
    }
    
    @IBAction func 预加载网络音频(_ sender: Any) {
        initPlayState()
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
//        callbackId += 1
//        play?.track = "12"
//        play?.volume = 0.3
//        play?.playSpeed = 1.0
//        play?.play(url: "https://file.risekid.cn/web/adventure/static/sound_107_1_3.8e1d0145.mp3")
//        
//        bridgeRespTimes[callbackId] = play?.startPlayTime
////        print("playTime is: \(play?.startPlayTime)")
        audioControlBtn.setTitle("暂停播放", for: .normal)
        
        //循环播放
        launchAudio()
//        playShotAudio()
        
//        currentItemIndex = 0
//        launchAudioItem()
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
        play?.stop(false)
    }

}

//预先
extension AVPlayerVc {
    
    func launchAudioItem() {
        
        if currentItemIndex >= cacheItem.count {
            currentItemIndex = 0
        }
        
//        if let pi = cacheItem[currentItemIndex] {
//            play?.play(item: pi)
//            bridgeRespTimes[callbackId] = play?.startPlayTime
//            currentItemIndex += 1
//        }
    }
    
}
extension AVPlayerVc {
    
    func launchAudio() {
        //存储可播放
        initPlayState()
        
        playShotAudio()
        
        currentTimerCount = 0.0
        //启动停止器
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self else { return print("timer nil block")}
            onTimerBlock()
        }
    }
    //每隔1.1秒播放一段1.0秒的音频，轨道设置为"12"
    func playShotAudio() {
        
//        if callbackId >= playState.count {
//            callbackId = 0
//        }
//        if let play = playState[callbackId] {
            
//            play.track = "\(callbackId)"
//            play.play(url: landingAudio)
//            addAVPlayerEvent(play: play)
            play?.play(url: landingAudio)
//            bridgeRespTimes[callbackId] = play?.startPlayTime
//            callbackId += 1
//        }
        
//        play?.volume = 0.3
//        play?.playSpeed = 1.0
//        play?.play(fileURL: landingAudio)
        
//        play?.play(url: "https://file.risekid.cn/web/adventure/static/sound_107_1_3.8e1d0145.mp3")
        
    }
    
    //预加载音频-
    func initPlayState() {
//        play.preparePlay(url: landingAudio)
//        let play1 = PTAudioPlayer()
        
//        play1.track = "\(callbackId)"
        
//        addAVPlayerEvent(play: play)

        playState[1] = false
        playState[2] = false
        playState[3] = false
    }
    
    func onTimerBlock() {
        currentTimerCount += 0.01
        
        let millisecond = currentTimerCount * 1000
//        print("定时进度: \(millisecond)毫秒")
        if millisecond > landingAudioDution && millisecond <= 2 * landingAudioDution {
            beginPlay(index: 1,progress: millisecond)
        } else if millisecond > 2 * landingAudioDution && millisecond <= 3 * landingAudioDution {
            beginPlay(index: 2,progress: millisecond)
        } else if millisecond > 3 * landingAudioDution {
            beginPlay(index: 3,progress: millisecond)
        }
        
        //播放结束
        if millisecond > 4 * landingAudioDution {
            timer?.invalidate()
            timer = nil
//            play?.stop()
        }
    }
    
    func beginPlay(index: Int, progress: Float) {
        
//        if let play = playState[callbackId], !play.isPlaying {
//            print("播放下一个：\(index)")
////            play.stop()
//            playShotAudio()
//        }
        if playState[index]  == false {
            
            playState[index] = true
            play?.stop(false)
            playShotAudio()
        }
    }
}
