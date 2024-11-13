//
//  GXAudioPlayerProtocol.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/11/28.
//

import Foundation
import AVFAudio
import RxSwift

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
    
    var startPlayTime: Double {get set}
    
    var track: String? {get set}
    
    var playSpeed: Float {get set}
    
    var volume: Float {get set}
    
    //是否播放
    var isPlaying: Bool {get}
    
    //是否支持循环播放
    var loop: Bool {get set}
  
    var disposeBag: DisposeBag {get set}
    ///循环次数
    var numberOfLoops: Int{get set}
    
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
    
    //进入前后台
    func receviedEventEnterBackground()
    
    func receviedEventEnterForeground()
}

//MARK: 控制音频会话
extension GXAudioPlayerProtocol {
    
    public func setAVAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category != AVAudioSession.Category.playAndRecord  {
            do {
                if #available(iOS 10.0, *) {//iOS 新增.allowAirPlay .allowBluetoothA2DP
                    try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
                } else {
                    try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
                }
            } catch {

            }
        }
        
        try? audioSession.setPreferredIOBufferDuration(0.005)
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {

        }
    }
    
    func addAcSetionRX() {
        NotificationCenter.default.rx.notification(AVAudioSession.interruptionNotification).subscribe(onNext: { [weak self] (notic) in
            guard let self else { return }
            interruptionTypeChanged(notic)
        }).disposed(by: self.disposeBag)
     
        NotificationCenter.default.rx.notification(AVAudioSession.routeChangeNotification).subscribe { [weak self] notic in
            guard let self else { return }
            routeChangeTyptChanged(notic)
        }.disposed(by: self.disposeBag)
    }
}

//MARK: - audio notification
extension GXAudioPlayerProtocol {
    
    ///打断
    private func interruptionTypeChanged(_ nof:Notification) {
        
        guard let userInfo = nof.userInfo, let reasonValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        
        switch reasonValue {
        case AVAudioSession.InterruptionType.began.rawValue://Began
            var isAnotherAudioSuspend = false //是否是被其他音频会话打断
            if #available(iOS 10.3, *) {
                if #available(iOS 14.5, *) {
                    // iOS 14.5之后使用InterruptionReasonKey
                    let reasonKey = userInfo[AVAudioSessionInterruptionReasonKey] as! UInt
                    switch reasonKey {
                    case AVAudioSession.InterruptionReason.default.rawValue:
                        //因为另一个会话被激活,音频中断
                        isAnotherAudioSuspend = true
                        break
                    case AVAudioSession.InterruptionReason.appWasSuspended.rawValue:
                        //由于APP被系统挂起，音频中断。
                        break
                    case AVAudioSession.InterruptionReason.builtInMicMuted.rawValue:
                        //音频因内置麦克风静音而中断(例如iPad智能关闭套iPad's Smart Folio关闭)
                        break
                    default: break
                    }
                    print("AVAudioSessionInterruption: \(reasonKey)")
                } else {
                    // iOS10.3-14.5，InterruptionWasSuspendedKey为true表示中断是由于系统挂起，false是被另一音频打断
                    let suspendedNumber:NSNumber = userInfo[AVAudioSessionInterruptionWasSuspendedKey] as! NSNumber
                    isAnotherAudioSuspend = !suspendedNumber.boolValue
                }
            }
            
            if isAnotherAudioSuspend {
                //                if (self.delegate != nil){
//                mediaChangeInterruptionType(begin: true)
                print("mediaChangeInterruptionType: 开始")
                receviedEventEnterBackground()
                //                }
            }
            break
        case AVAudioSession.InterruptionType.ended.rawValue://End
            let optionKey = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
            if optionKey == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                //指示另一个音频会话的中断已结束，本应用程序可以恢复音频。
                //                if (self.delegate != nil){
//                mediaChangeInterruptionType(begin: false)
                receviedEventEnterForeground()
                print("mediaChangeInterruptionType: 结束")
                //                }
            }
            break
        default: break
        }
    }
    
    ///耳机
    private func routeChangeTyptChanged(_ nof:Notification) {
        print("audio session route change \(nof)")
        
        guard let userInfo = nof.userInfo else { return }
        var seccReason = ""
        guard let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt else {return}
        
        switch reason {
        case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
            seccReason = "有新设备可用"
            // 一般为接入了耳机,参数为旧设备的信息。
            guard let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription  else {
                return
            }
            if previousRoute.inputs.count <= 0 && previousRoute.outputs.count <= 0 {
                return
            }

            let previousOutput = previousRoute.outputs[0]
            let portType = previousOutput.portType
            print("音频模式更改:有新设备可用通知- \(portType.rawValue)")
            if portType == AVAudioSession.Port.headphones {
                //在这里暂停播放, 更改输出设备，录音时背景音需要重置。否则无法消音
                print("耳机🎧模式")
            } else if portType == AVAudioSession.Port.builtInSpeaker {
                print("Built-in speaker on an iOS device")
            }
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
            seccReason = "老设备不可用"
            guard let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription  else {
                return
            }
            if previousRoute.inputs.count <= 0 && previousRoute.outputs.count <= 0 {
                return
            }
            let previousOutput = previousRoute.outputs[0]
            let portType = previousOutput.portType
            print("音频模式更改:老设备不可用通知- \(portType.rawValue)")
            if portType == AVAudioSession.Port.headphones {
                print("耳机🎧模式")
                if isPlaying {
                    self.resume()
                }
            } else if portType == AVAudioSession.Port.builtInSpeaker {
                
            }
        case AVAudioSession.RouteChangeReason.categoryChange.rawValue:
            seccReason = "类别Cagetory改变了"
        case AVAudioSession.RouteChangeReason.override.rawValue:
            seccReason = "App重置了输出设置"
        case AVAudioSession.RouteChangeReason.wakeFromSleep.rawValue:
            seccReason = "从睡眠状态呼醒"
        case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory.rawValue:
            seccReason = "当前Category下没有合适的设备"
            
        case AVAudioSession.RouteChangeReason.routeConfigurationChange.rawValue:
            seccReason = "Rotuer的配置改变了"
//        case AVAudioSession.RouteChangeReason.unknown,
        default:
            seccReason = "未知原因"
        }
    }
}


//extension GXAudioPlayerProtocol {
//    func getDeviceOutputInfo(portType: AVAudioSession.Port) -> String {
//        var type = ""
//        switch portType {
//        case .headsetMic:
//            type = "headsetMic"
//        case .builtInMic:
//            type = "内置麦克风"
//        case .builtInSpeaker:
//            type = "内置扬声器"
//        case .headphones:
//            type = "插线耳机"
//        case .bluetoothA2DP:
//            type = "蓝牙音频传输模型协议"
//        case .bluetoothLE:
//            type = "低功耗蓝牙"
//        case .airPlay:
//            type = "隔空播放"
//
//        default:
//            type = "内置扬声器"
//        }
//        return type
//    }
//}
