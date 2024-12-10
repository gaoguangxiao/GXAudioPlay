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
    case LogError(String) //播放器错误日志
}

public protocol GXAudioPlayerProtocol: NSObjectProtocol{
    
    var track: String? {get set}
    
    var playSpeed: Float {get set}
    
    var volume: Float {get set}
    
    //是否支持循环播放
    var loop: Bool {get set}
  
    ///循环次数
    var numberOfLoops: Int{get set}
    
    var playEventsBlock: ((PTAudioPlayerEvent)->())? { get set }
    
    //播放本地URL
    
    //播放网络
    func play(url: String) throws

    //暂停
    func pause()
    
    //继续播放
    func resume() throws
    
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

//MARK: 控制音频会话
extension GXAudioPlayerProtocol {
    
    //检查类别的条件不一定能反映完整的会话状态
    //        可能的错误原因
    //        资源冲突：某些设备或系统应用正在占用音频资源，导致无法激活会话
    //        选项冲突：选项配置可能不被设备或系统完全支持
    //        中断未恢复：中断而被停止
    public func configureAudioSessionForPlayAndRecord() throws {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // 检查当前类别并重新设置
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(.playAndRecord, options: [
                    .defaultToSpeaker,
                    .allowBluetooth,
                    .allowAirPlay,
                    .allowBluetoothA2DP
                ])
                print("AVAudioSession 类别已设置为 playAndRecord")
            }
            // 激活音频会话
            try audioSession.setActive(true)
            print("AVAudioSession 已激活")
        } catch {
            // 捕获和打印错误信息
            print("设置 AVAudioSession 失败: \(error.localizedDescription)")
            throw error
        }
    }

    public func configureAudioSessionForPlayback() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // 设置音频会话为播放模式，不涉及录音
            try audioSession.setCategory(.playback, options: [
                .allowBluetooth,     // 如果允许通过蓝牙播放
                .allowAirPlay        // 如果允许通过 AirPlay 播放
            ])
            
            // 激活音频会话
            try audioSession.setActive(true)
            print("AVAudioSession 已激活为 playback 模式")
        } catch {
            print("configureAudioSessionForPlayback 配置 AVAudioSession 失败: \(error.localizedDescription)")
            throw error
        }
    }
}
