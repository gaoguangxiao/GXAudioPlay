//
//  Parser+PropertyListener.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2023/12/4.
//

import Foundation
import AVFoundation

func ParserPropertyChangeCallback(_ context: UnsafeMutableRawPointer, 
                                  _ streamID: AudioFileStreamID,
                                  _ propertyID: AudioFileStreamPropertyID,
                                  _ flags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
    
    /// Parse the various properties
//    switch propertyID {
//    case kAudioFileStreamProperty_DataFormat:
//        var format = AudioStreamBasicDescription()
//        GetPropertyValue(&format, streamID, propertyID)
////        parser.dataFormatD = AVAudioFormat(streamDescription: &format)
//        
//    case kAudioFileStreamProperty_AudioDataPacketCount:
////        GetPropertyValue(&parser.packetCount, streamID, propertyID)
//
//    default:
//        ()
//    }
}

// MARK: - Utils

/// Generic method for getting an AudioFileStream property. This method takes care of getting the size of the property and takes in the expected value type and reads it into the value provided. Note it is an inout method so the value passed in will be mutated. This is not as functional as we'd like, but allows us to make this method generic.
///
/// - Parameters:
///   - value: A value of the expected type of the underlying property
///   - streamID: An `AudioFileStreamID` representing the current audio file stream parser.
///   - propertyID: An `AudioFileStreamPropertyID` representing the particular property to get.
func GetPropertyValue<T>(_ value: inout T, _ streamID: AudioFileStreamID, _ propertyID: AudioFileStreamPropertyID) {
    var propSize: UInt32 = 0
    guard AudioFileStreamGetPropertyInfo(streamID, propertyID, &propSize, nil) == noErr else {
//        os_log("Failed to get info for property: %@", log: Parser.loggerPropertyListenerCallback, type: .error, String(describing: propertyID))
        return
    }
    
    guard AudioFileStreamGetProperty(streamID, propertyID, &propSize, &value) == noErr else {
//        os_log("Failed to get value [%@]", log: Parser.loggerPropertyListenerCallback, type: .error, String(describing: propertyID))
        return
    }
}
