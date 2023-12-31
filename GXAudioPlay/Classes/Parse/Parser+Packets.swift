//
//  Parser+Packets.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/12/4.
//

import Foundation
import AudioToolbox
import os.log

//2.4、解析回调，处理数据 分离音频帧,
func ParserPacketCallback(_ context: UnsafeMutableRawPointer, _ byteCount: UInt32, _ packetCount: UInt32, _ data: UnsafeRawPointer, _ packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>?) {
    guard let aspd = packetDescriptions else {
        return
    }
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
    let packetDescriptionsOrNil: UnsafeMutablePointer<AudioStreamPacketDescription>? = packetDescriptions
    let isCompressed = packetDescriptionsOrNil != nil
    os_log("%@ - %d [bytes: %i, packets: %i, compressed: %@]", log: Parser.loggerPacketCallback, type: .debug, #function, #line, byteCount, packetCount, "\(isCompressed)")
    
    /// Iterate through the packets and store the data appropriately
    if isCompressed {
        for i in 0 ..< Int(packetCount) {
            let packetDescription = aspd[i]
            let packetStart = Int(packetDescription.mStartOffset)
            let packetSize = Int(packetDescription.mDataByteSize)
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, packetDescription))
        }
    } else {
        
        /// At this point we should definitely have a data format
        guard let dataFormat = parser.dataFormat else {
            return
        }
        print("dataFormat.commonFormat: \(dataFormat.commonFormat) \n  dataFormat.sampleRate: \(dataFormat.sampleRate) \n  dataFormat.channelCount: \(dataFormat.channelCount)")
        
        
        let format = dataFormat.streamDescription.pointee
        let bytesPerPacket = Int(format.mBytesPerPacket)
        for i in 0 ..< Int(packetCount) {
            let packetStart = i * bytesPerPacket
            let packetSize = bytesPerPacket
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, nil))
        }
    }
}
