//
//  GXAudioPlayerProtocol.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/11/28.
//

import Foundation
import AVFAudio
import RxSwift

enum AudioPlayerErrorStatus: Int, Error {
    case timerOutPlaying = 1
    case timerOutEnd
}

public enum PTAudioPlayerEvent: Equatable {
    case None
    case Playing(Double)         // 在媒体开始播放时触发（不论是初次播放、在暂停后恢复、或是在结束后重新开始）
    case TimeUpdate(Double)
    case Waiting         //在一个待执行的操作（如回放）因等待另一个操作（如跳跃或下载）被延迟时触发
    case Pause
    case Interruption    //音频被中断
    case Ended
    case LoopEndSingle   //单次循环结束
    case Error(NSError) //错误信息
    case LogError(String) //播放器错误日志
}

public protocol GXAudioPlayerProtocol: NSObjectProtocol{
    
    var track: String {get set}
    
    var audioPath: String {get set}
    
    var playSpeed: Float {get set}
    
    var volume: Float {get set}
    
    //是否支持循环播放
    var loop: Bool {get set}
    
    ///循环次数
    var numberOfLoops: Int{get set}
    
    // Callback playback progress
    var timeEvent: Bool{get set}
    
    ///
    var playEventsBlock: ((PTAudioPlayerEvent)->())? { get set }
    
    var status : PTAudioPlayerEvent {get set}
    
    /// audio duration
    var duration: Double {get}
    
    //开始播放
    var startTime: Date {get set}
    
    /// 播放完毕时间
    var playbackDuration: Double{get set}
    
    //
    var disposeBag: DisposeBag {get set}
    
    //是否播放
    var isPlaying: Bool{get}
    
    //播放网络
    func play(url: String) throws
    
    //暂停
    func pause(isSystemControls: Bool)
    
    //继续播放
    func resume(isSystemControls: Bool)
    
    func stop()
    
    func stop(_ issue : Bool)
    
    // Slide a second to play
    func setSeekToTime(seconds: Double)
    
    var isRunning: Bool {get set}
    
    //是否具备超时定时器
    var isLaunchOverTimer: Bool {get set}
    
    //超时定时器
    var overTimer: Timer?{get set}

    // 准备播放时间 超时
    var canPlayResultCount: Double {get set}
    
    //开始播放
    var canPlayResult: Bool{get set}
    
    // 播放音频时间超时+ 5秒容错
    var playingEndTime: Double {get set}
    
    // 合计播放时间
    var currentPlayCount: Double {get set}
}

//MARK: 控制音频会话
extension GXAudioPlayerProtocol {
    
    public var isPlaying: Bool {
        get {
            if case .Playing = self.status {
                return true
            }
            return false
        }
    }
}

extension GXAudioPlayerProtocol {
    
    public func handleAudioSessionNotification() {
        // 播放器被中断
        NotificationCenter.default.rx.notification(AVAudioSession.interruptionNotification).subscribe(onNext: { [weak self] (notic) in
            guard let self else { return }
            interruptionTypeChanged(notic)
        }).disposed(by: self.disposeBag)
        
        //耳机插拔
        NotificationCenter.default.rx.notification(AVAudioSession.routeChangeNotification).subscribe { [weak self] notic in
            guard let self else { return }
            routeChangeTyptChanged(notic)
        }.disposed(by: self.disposeBag)
        
        
        //进入后台
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else {return}
//                self.pauseOverTimer()
                mediaChangeInterruptionType(begin: true)
            }).disposed(by: disposeBag)
        
        //进入前台
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else {return}
                //中断恢复
                mediaChangeInterruptionType(begin: false)
            }).disposed(by: disposeBag)
    }
    
    ///打断
    public func interruptionTypeChanged(_ nof:Notification) {
        
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
                mediaChangeInterruptionType(begin: true)
                print("\(track)、mediaChangeInterruptionType: 开始")
                //                }
            }
            break
        case AVAudioSession.InterruptionType.ended.rawValue://End
            let optionKey = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
            if optionKey == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                //指示另一个音频会话的中断已结束，本应用程序可以恢复音频。
                //                if (self.delegate != nil){
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    // 恢复播放或录制
                } catch {
                    print("无法激活音频会话: \(error.localizedDescription)")
                    self.playEventsBlock?(.LogError("setActive:\(error.localizedDescription)"))
                }
                mediaChangeInterruptionType(begin: false)
                print("\(track)、mediaChangeInterruptionType: 结束")
                //                }
            }
            break
        default: break
        }
    }
    
    ///  Audio session change notification
    ///   audio play by status
    func mediaChangeInterruptionType(begin: Bool) {
        var needPause = false
        if case .Playing = self.status  { needPause = true }
        if case .Waiting = self.status  { needPause = true }
        if begin {
            if needPause  {
                self.pause(isSystemControls: true)
            }
        } else {
            if needPause  {
                self.resume(isSystemControls: true)
            }
        }
    }
    
    
    ///耳机
    public func routeChangeTyptChanged(_ nof:Notification) {
        //        print("audio session route change \(nof)")
        
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
//                if case .Playing = self.status {
//                    self.resume(isSystemControls: true)
//                }
                mediaChangeInterruptionType(begin: false)
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

extension GXAudioPlayerProtocol {
    
    /// Logs the duration of audio playback.
    public func logPlaybackDuration() {
        let endTime = Date()
        self.playbackDuration = endTime.timeIntervalSince(startTime)
        //print("Audio playback duration: \(duration) seconds")
    }
    
    public func addOverTimer() {
        isRunning = true
        overTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self else {
                return
            }
            currentPlayCount += 0.1
//            print("track：\(track)、\(audioPath)、计时：\(currentPlayCount)、Playing：\(canPlayResult)、canPlayResultCount：\(canPlayResultCount)、dutaion:\(duration)、playingEndTime:\(playingEndTime)")
            // 在这里更新 UI 或执行其他操作
            // 不可播放，准备时间超时了
            if !canPlayResult, currentPlayCount > canPlayResultCount {
                //规定时间不可播放
                playEventsBlock?(PTAudioPlayerEvent.Error(
                    NSError(domain: "com.gxaudioplay.app",
                            code: -1001,
                            userInfo: ["NSLocalizedDescriptionKey":"timerOut.Playing:\(audioPath)",
                                       "NSLocalizedFailureReasonErrorKey":"timerOut.Playing",
                                       "NSLocalizedRecoverySuggestionErrorKey":"Please check Networking"])
                ))
                removeOverTimer()
                stop()
            }
            //已经开始播放，超时未停止
            if canPlayResult, currentPlayCount >= playingEndTime {
                //timerOut.End
                playEventsBlock?(PTAudioPlayerEvent.Error(NSError(domain: "com.gxaudioplay.app",
                                                                  code: -1002,
                                                                  userInfo: ["NSLocalizedDescriptionKey":"timerOut.End:\(audioPath)",
                                                                             "NSLocalizedFailureReasonErrorKey":"timerOut.End",
                                                                             "NSLocalizedRecoverySuggestionErrorKey":"Please check Networking or reset app device"])
                ))
                removeOverTimer()
                stop()
            }
        }
        if !Thread.isMainThread {
            if let overTimer {
                RunLoop.current.add(overTimer, forMode: .common)
                RunLoop.current.run()
            }
        }
    }
    
    //初始化超时
    func initOverTimer(overDuration: Double, canPlay: Bool) {
        isLaunchOverTimer = true
        self.removeOverTimer()
        canPlayResult = canPlay
        canPlayResultCount = overDuration
        //播放超时
        playingEndTime = overDuration
        currentPlayCount = 0
        //开始计数
        addOverTimer()
    }
    
    public func pauseOverTimer() {
        guard isLaunchOverTimer else {
            return
        }
        guard isRunning else {
            return
        }
        isRunning = false
        removeOverTimer()
    }
    
    public func resumeOverTimer() {
        guard isLaunchOverTimer else {
            return
        }
        //移除
        removeOverTimer()
        //重新创建
        addOverTimer()
    }
    
    public func removeOverTimer() {
        isRunning = false
        overTimer?.invalidate()
        overTimer = nil
    }
}
