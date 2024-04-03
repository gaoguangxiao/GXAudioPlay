//
//  GXAudioPlayerProtocol.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/11/28.
//

import Foundation
import AVFAudio

public enum PTAudioPlayerEvent: Equatable {
    case None
    case Playing(Double)         // 在媒体开始播放时触发（不论是初次播放、在暂停后恢复、或是在结束后重新开始）
    case TimeUpdate(Double)
    case Waiting         //在一个待执行的操作（如回放）因等待另一个操作（如跳跃或下载）被延迟时触发
    case Pause
    case Interruption    //音频被中断
    case Ended
    case LoopEndSingle   //单次循环结束
    case Error(String)
}

public protocol GXAudioPlayerProtocol: NSObjectProtocol{
    
    var playSpeed: Float {get set}
    
    var volume: Float {get set}
    
    //是否支持循环播放
    var loop: Bool {get set}
  
    var playEventsBlock: ((PTAudioPlayerEvent)->())? { get set }
    
    //播放本地URL
    
    //播放网络
    func play(url: String)

    //暂停
    func pause()
    
    //继续播放
    func resume()
    
    func stop()
    
    func stop(_ issue : Bool)
//
//    //拖动到某秒进行播放
//    public func setSeekToTime(seconds: Double)
    func setSeekToTime(seconds: Double)
    
    //时间
    func addPeriodicTimer ()
    
    func removePeriodicTimer()
}

//protocol GXAudioPlayerEventProtocol {
//    //内部事件变化
//    func playEventUpdate(event: OTA)
//}

//MARK: 控制音频会话
public extension GXAudioPlayerProtocol {
    
    func setAVAudioSession() {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            } catch {
                
            }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            
        }
    }
}

//public func setSeekToTime(seconds: Double)  {
//    // 拖动改变播放进度
//    let targetTime: CMTime = CMTimeMake(value: Int64(seconds), timescale: 1)
//    //播放器定位到对应的位置
//    self.currentAudioPlayer?.seek(to: targetTime)
//}
