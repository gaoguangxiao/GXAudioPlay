//
//  Jump.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/11/9.
//

import Foundation
import AVFAudio

class T: NSObject {
    
    func test() {
        
        if #available(iOS 17.0, *) {
            let audioApp = AVAudioApplication.shared
            
            AVAudioApplication.requestRecordPermission { b in
                
                print("输出录制权限\(b)")
            }
        } else {
            // Fallback on earlier versions
        }
        
        
//        audioApp.re
    }
}
