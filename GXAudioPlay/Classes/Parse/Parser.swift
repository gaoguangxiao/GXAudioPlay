//
//  Parser.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/12/4.
//  解析器

import Foundation
import AudioToolbox
import AVFAudio
import os.log

/// The `Parser` is a concrete implementation of the `Parsing` protocol used to convert binary data into audio packet data. This class uses the Audio File Stream Services to progressively parse the properties and packets of the incoming audio data.
public class Parser: Parsing {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser")
    static let loggerPacketCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.Packets")
    static let loggerPropertyListenerCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.PropertyListener")
    
    // MARK: - Parsing props
    
    public internal(set) var dataFormat: AVAudioFormat?
    public internal(set) var packets = [(Data, AudioStreamPacketDescription?)]()
    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = dataFormat else {
            return nil
        }
        print("AVAudioPacketCount(packetCount): \(AVAudioPacketCount(packetCount))\n\nAVAudioPacketCount(packets.count):\(AVAudioPacketCount(packets.count))")
        
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packets.count))
    }
    
    // MARK: - Properties
    
    /// A `UInt64` corresponding to the total frame count parsed by the Audio File Stream Services
    public internal(set) var frameCount: UInt64 = 0
    
    /// A `UInt64` corresponding to the total packet count parsed by the Audio File Stream Services
    public internal(set) var packetCount: UInt64 = 0
    
    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    fileprivate var streamID: AudioFileStreamID?
    
    // MARK: - Lifecycle
    
    /// Initializes an instance of the `Parser`
    ///
    /// - Throws: A `ParserError.streamCouldNotOpen` meaning a file stream instance could not be opened
    public init() throws {
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    // MARK: - Methods
    
    public func parse(data: Data) throws {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        let streamID = self.streamID!
        let count = data.count
        _ = try data.withUnsafeBytes({ (rawBufferPointer) in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            if let address = bufferPointer.baseAddress{
                let result = AudioFileStreamParseBytes(streamID, UInt32(count), address, [])
                guard result == noErr else {
                    os_log("Failed to parse bytes", log: Parser.logger, type: .error)
                    throw ParserError.failedToParseBytes(result)
                }
            }
        })
    }

}
