//
//  String+Extension.swift
//  wisdomstudy
//
//  Created by ggx on 2017/8/30.
//  Copyright © 2017年 高广校. All rights reserved.
//

import Foundation
import UIKit

public extension String {
    var length: Int {
        return count
    }
    
    /// 预估尺寸，根据字体、宽度
    func size(font: UIFont, width: CGFloat = SCREEN_WIDTH_STATIC) -> CGSize {
        return (self as NSString).boundingRect(with: CGSize(width: width, height: CGFloat(HUGE)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil).size
    }
    
    /// 预估尺寸，根据字体
    func size(of font: UIFont) -> CGSize {
        return self.boundingRect(with: CGSize(width: Double.greatestFiniteMagnitude, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil).size
    }
    
    /// 预估宽度，根据size
    func width(of font: UIFont, size: CGSize) -> Int {
        let boundingSize = self.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil).size
        let width = Int(boundingSize.width)
        return width + 1
    }
    
    /// 是否包含某个字符串
    func has(_ s: String) -> Bool {
        return range(of: s) != nil
    }
    
    /// 分割字符
    func split(_ s: String) -> [String] {
        if s.isEmpty {
            return []
        }
        return components(separatedBy: s)
    }
    
    func range(of searchString: String) -> NSRange {
        return (self as NSString).range(of: searchString)
    }
    
    /// 去掉左右空格
    func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func replace(_ old: String, new: String) -> String {
        return replacingOccurrences(of: old, with: new, options: NSString.CompareOptions.numeric, range: nil)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        return String(self[..<index(from: to)])
    }
    
    func index(from: Int) -> Index {
        return index(startIndex, offsetBy: from)
    }
    
    func substring(fromIndex: Int, toIndex: Int) -> String {
        let range = NSRange(location: fromIndex, length: toIndex - fromIndex)
        return substr(with: range)
    }
    
    func substr(with range: NSRange) -> String {
        let start = index(startIndex, offsetBy: range.location)
        let end = index(endIndex, offsetBy: range.location + range.length - count)
        return String(self[start..<end])
    }
    
    func toBool() -> Bool? {
        switch self {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return nil
        }
    }
    
    func toInt64() -> Int64? {
        return Int64(self)
    }
    
    func toDouble() -> Double {
        return (Double(self) ?? 0)
    }
}

// MARK: - URL Encode & Decode
public extension String {
    var toUrl: URL? {
        if let url = URL.init(string: self) {
            return url
        }
        let charSet = CharacterSet.urlQueryAllowed as NSCharacterSet
        let mutSet = charSet.mutableCopy() as! NSMutableCharacterSet
        mutSet.addCharacters(in: "#")
        let result = self.addingPercentEncoding(withAllowedCharacters: mutSet as CharacterSet)
        return URL(string: result ?? "")
    }
    
    var toFileUrl: URL? {
        var url : URL?
        if #available(iOS 16.0, *) {
            url = URL(filePath: self)
        } else {
            // Fallback on earlier versions
            url = URL(fileURLWithPath: self)
        }
        return url
    }
    
    var URLEncode: String {
        let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let unreservedCharset = CharacterSet(charactersIn: unreservedChars)
        
        return addingPercentEncoding(withAllowedCharacters: unreservedCharset) ?? self
    }
    
    var URLDecode: String {
        return removingPercentEncoding ?? self
    }
    
    var URLAddingPercentEncodingInQuery: String {
        let allowedCharacters = CharacterSet.urlQueryAllowed
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? self
    }
    
    var urlParamterEncode: String {
        func encodeParamterValue(paramter: String) -> String {
            let query = paramter.components(separatedBy: "=")
            guard query.count == 2 else { return paramter }
            let key: String = query.first ?? ""
            let value: String = query.last ?? ""
            let encodeParamter = "\(key)=\(value.URLEncode)"
            return encodeParamter
        }
        
        guard !self.isEmpty else { return self }
        let baseUrl = "?"
        guard self.contains(baseUrl) && (self.hasPrefix("https://") || self.hasPrefix("http://"))
        else { return self }
        
        let range = self.range(of: baseUrl)
        // get  "https://www.baidu.com?"
        let headerStrig = self.substring(to: range.location + range.length)
        // get key1=value1&key2=value2
        let paramterString = self.substring(from: range.location + range.length)
        // encode paramter
        var paramters = paramterString.components(separatedBy: "&")
        guard !paramters.isEmpty else { return self }
        for i in 0...paramters.count - 1 {
            var paramter = paramters[i]
            paramter = encodeParamterValue(paramter: paramter)
            paramters[i] = paramter
        }
        let encodeString = "\(paramters.joined(separator: "&"))"
        
        return "\(headerStrig)\(encodeString)"
    }
}

// MARK: Function of NSString
public extension String {
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    var stringByDeletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    var stringByDeletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    var pathComponents: [String] {
        return (self as NSString).pathComponents
    }
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
    func stringByAppendingPathExtension(ext: String) -> String? {
        let nsSt = self as NSString
        return nsSt.appendingPathExtension(ext)
    }
}

extension String {
    /// 核实合法手机号码
    public func isValidPhoneNumber() -> Bool { self.verification(pattern: "^1\\d{10}$") }
    
    /// 验证字符串匹配结果是否符合要求，返回布尔值
    fileprivate func verification(pattern: String) -> Bool { (self.matching(pattern: pattern)?.count ?? 0) > 0 }
    
    /// 获取匹配结果的数组
    public func matching(pattern: String, options: NSRegularExpression.Options = .caseInsensitive) -> [NSTextCheckingResult]? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        return regex?.matches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, self.count))
    }
}
