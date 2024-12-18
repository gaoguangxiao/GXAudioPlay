//
//  String+Extension.swift
//  GXAudioPlay
//
//  Created by 高广校 on 2024/12/18.
//

import Foundation

public extension String {
    
    var encodeLocalOrRemoteForUrl: URL? {
        let canUseCache = FileManager.default.fileExists(atPath: self)
        var audioUrl: URL?
        if canUseCache {
            var fileUrl : URL?
            if #available(iOS 16.0, *) {
                fileUrl = URL(filePath: self)
            } else {
                // Fallback on earlier versions
                fileUrl = URL(fileURLWithPath: self)
            }
            audioUrl = fileUrl
        } else {
            guard let escapedURLString = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                return nil
            }
            audioUrl = URL(string: escapedURLString)
        }
        return audioUrl
    }
}
