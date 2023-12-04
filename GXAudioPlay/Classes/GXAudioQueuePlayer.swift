//
//  GXAudioQueuePlayer.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/11/9.
//

import Foundation
import CoreAudioTypes
import AudioToolbox

struct AQPlayerState {
    var mDataFormat : AudioStreamBasicDescription
    var mQueue : AudioQueueRef
    var mAudioFile  : UnsafeMutablePointer<AudioFileID?>
//    AudioQueueBufferRef           mBuffers[kNumberBuffers];       // 4
//    AudioFileID                   mAudioFile;                     // 5
//    UInt32                        bufferByteSize;                 // 6
//    SInt64                        mCurrentPacket;                 // 7
//    UInt32                        mNumPacketsToRead;              // 8
//    AudioStreamPacketDescription  *mPacketDescs;                  // 9
//    bool                          mIsRunning;                     // 10
//    init(mDataFormat: AudioStreamBasicDescription, mAudioFile: UnsafeMutablePointer<AudioFileID?>) {
//        self.mDataFormat = mDataFormat
//        self.mAudioFile = mAudioFile
//    }
}

class GXAudioQueuePlayer: NSObject {
    
}
