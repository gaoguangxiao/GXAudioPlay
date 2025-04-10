//
//  File.swift
//  DaDaBaby
//
//  Created by FreakyYang on 2018/10/23.
//  Copyright © 2018年 jerry.li. All rights reserved.
//

import Foundation

private let fileManagerDefault = FileManager.default

extension FileManager {
    
    /// 文件类型
    public enum FileType {
        case file
        case directory
    }
    
    /// 移动类型
    public enum MoveFileType {
        case move
        case copy
    }
}


public extension FileManager {
    
    /**
     * 计算单个文件的大小
     */
    static func fileSize(path: String) -> Double {
        let manager = FileManager.default
        var fileSize: Double = 0
        do {
            let attr = try manager.attributesOfItem(atPath: path)
            fileSize = Double(attr[FileAttributeKey.size] as? UInt64 ?? 0)
            let dict = attr as NSDictionary
            fileSize = Double(dict.fileSize())
        } catch {
            dump(error)
        }
        return fileSize/1024/1024
    }
    
    /**
     * 遍历所有子目录， 并计算文件大小
     */
    static func folderSizeAtPath(folderPath: String) -> Double {
        let manage = FileManager.default
        if !manage.fileExists(atPath: folderPath) {
            return 0
        }
        let childFilePath = manage.subpaths(atPath: folderPath)
        var fileSize: Double = 0
        guard let nnChildFilePath = childFilePath else { return 0 }
        for path in nnChildFilePath {
            let fileAbsoluePath = folderPath+"/"+path
            fileSize += self.fileSize(path: fileAbsoluePath)
        }
        return fileSize
    }
}

extension  FileManager {
    
    /// Caches
    public static var cachesURL: URL? {
        fileManagerDefault.urls(for: .cachesDirectory, in: .userDomainMask).last
    }
    public static var cachesPath: String? {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
    }
    
    /// Documents
    public static var documentURL: URL? {
        fileManagerDefault.urls(for: .documentDirectory, in: .userDomainMask).last
    }
    public static var documentPath: String? {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    /// Library
    public static var libraryURL: URL? {
        fileManagerDefault.urls(for: .libraryDirectory, in: .userDomainMask).last
    }
    
    public static var libraryPath: String? {
        NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
    }
    
    /// 创建文件夹(蓝色的，文件夹和文件是不一样的)
    @discardableResult
    public static func createFolder(atPath path: String, block: ((_ isSuccess: Bool) -> Void)? = nil) -> Bool {
        if !isFileExists(atPath: path) { // 不存在的路径才会创建
            do {
                // withIntermediateDirectories为ture表示路径中间如果有不存在的文件夹都会创建
                try fileManagerDefault.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                block?(true)
                return true
            } catch _ {
                block?(false)
                return false
            }
        } else {
            block?(true)
            return true
        }
    }
    
    /// 创建文件路径
    @discardableResult
    public static func createFile(atPath path: String, block: ((_ isSuccess: Bool) -> Void)? = nil) -> Bool {
        if !isFileExists(atPath: path) { // 不存在的路径才会创建
            let isSuccess = fileManagerDefault.createFile(atPath: path, contents: nil, attributes: nil)
            block?(isSuccess)
            return isSuccess
        } else {
            block?(false)
            return false
        }
    }
    
    /// 移除文件目录
    @discardableResult
    public static func removefolder(atPath path: String, block: ((_ isSuccess: Bool) -> Void)? = nil) -> Bool {
        if isFileExists(atPath: path) {
            do {
                // 开始移除文件目录
                try fileManagerDefault.removeItem(atPath: path)
                block?(true)
                return true
            } catch _ {
                block?(false)
                return false
            }
        } else {
            block?(true)
            return true
        }
    }
    
    /// 移除文件
    @discardableResult
    public static func removefile(atPath path: String, block: ((_ isSuccess: Bool) -> Void)? = nil) -> Bool {
        if isFileExists(atPath: path) {
            do {
                // 开始移除文件
                try fileManagerDefault.removeItem(atPath: path)
                block?(true)
                return true
            } catch _ {
                block?(false)
                return false
            }
        } else {
            block?(true)
            return true
        }
    }
    
    /// 移动文件路径到另一个文件路径
    public static func moveFile(fromFilePath: String, toFilePath: String,
                                fileType: FileManager.FileType = .file,
                                moveType: FileManager.MoveFileType = .move,
                                isOverwrite: Bool = true, block: ((_ isSuccess: Bool) -> Void)? = nil) {
        // 先判断被拷贝路径是否存在
        if !isFileExists(atPath: fromFilePath) {
            block?(false)
        } else {
            // 判断拷贝后的文件路径的前一个文件路径是否存在，如果不存在就进行创建
            let toFileFolderPath = directory(atPath: toFilePath)
            if !isFileExists(atPath: toFilePath) && fileType == .file ?
                !createFile(atPath: toFilePath) :
                    !createFolder(atPath: toFileFolderPath)  {
                block?(false)
            } else {
                if isOverwrite && isFileExists(atPath: toFilePath) {
                    // 如果被移动的件夹或者文件，如果已存在，先删除，否则拷贝不了
                    do {
                        try fileManagerDefault.removeItem(atPath: toFilePath)
                    } catch _ {
                        
                    }
                }
                
                // 移动文件夹或者文件
                do {
                    if moveType == .move {
                        try fileManagerDefault.moveItem(atPath: fromFilePath, toPath: toFilePath)
                    } else {
                        try fileManagerDefault.copyItem(atPath: fromFilePath, toPath: toFilePath)
                    }
                    block?(true)
                } catch _ {
                    block?(false)
                }
            }
        }
    }
    
    /// 判断文件是否存在
    public static func isFileExists(atPath path: String) -> Bool {
        fileManagerDefault.fileExists(atPath: path)
    }
    
    /// 获取 (文件夹/文件) 的前一个路径
    public static func directory(atPath path: String) -> String {
        (path as NSString).deletingLastPathComponent
    }
    
    /// 根据文件路径获取文件扩展类型
    public static func fileSuffix(atPath path: String) -> String {
        (path as NSString).pathExtension
    }
    
    /// 获取所有文件路径
    public static func getAllFiles(atPath folderPath: String) -> [Any]? {
        // 查看文件夹是否存在，如果存在就直接读取，不存在就直接反空
        if isFileExists(atPath: folderPath) {
            return fileManagerDefault.enumerator(atPath: folderPath)?.allObjects
        }
        return nil
    }
    
    /// 获取所有文件名（性能要比getAllFiles差一些）
    public static func getAllFileNames(atPath folderPath: String) -> [String]? {
        // 查看文件夹是否存在，如果存在就直接读取，不存在就直接反空
        if (isFileExists(atPath: folderPath)) {
            return fileManagerDefault.subpaths(atPath: folderPath)
        }
        return nil
    }
    
    /// 获取目录下所有文件的全路径
    public static func getAllTotalFiles(atPath folderPath: String) -> [String]? {
        guard let files = getAllFiles(atPath: folderPath) else {
            return nil
        }
        return files.map {
            folderPath + "/"+"\($0)"
        }
    }
    
    /// 计算单个文件的大小
    public static func fileSize(atPath path: String) -> Double {
        guard let attr = try? fileManagerDefault.attributesOfItem(atPath: path) else {
            return 0
        }
        return Double(attr[FileAttributeKey.size] as? UInt64 ?? 0)
    }
    
    /// 遍历所有子目录，并计算所有文件总大小
    public static func fileFolderSize(atPath folderPath: String) -> Double {
        var fileSize: Double = 0
        guard let files = getAllTotalFiles(atPath: folderPath) else {
            return fileSize
        }
        files.forEach {
            (file) in fileSize += self.fileSize(atPath: file)
        }
        return fileSize
    }
    
}

extension FileManager {
    
    /// 其path为相对path，默认
    public static func deleteFileByPath(_ path: String? = nil, _ folderName: String? = nil) {
        if let path {
            let fileAtPath = self.filePath(folder: folderName, path: path, fileExt: "wav")
            if FileManager.isFileExists(atPath: fileAtPath) {
                FileManager.removefile(atPath: fileAtPath)
            }
        } else {
            let folderPath = getSynthesisfolderPath(folder: folderName)
            FileManager.removefolder(atPath: folderPath)
        }
    }
    
    /// 构建目录
    public static func create(_ systemFolder: String? = nil,
                       folder: String? = nil,
                       path: String, 
                       fileExt: String) -> String {
        let resourceFolder = getSynthesisfolderPath(folder: folder)
        // 资源目录下 创建文件
        let filePath =  "\(resourceFolder)\(path.stringByDeletingLastPathComponent)"
        //创建指定路径下，前面所有的文件夹
        FileManager.createFolder(atPath:filePath)
        return "\(filePath)/\(path.lastPathComponent).\(fileExt)"
    }
    
    /// 获取资源路径
    public static func filePath(_ systemFolder: String? = nil,
                  folder: String? = nil,
                  path: String,
                  fileExt: String) -> String {
        // 存放至 系统沙盒某目录
        let resourceFolder = getSynthesisfolderPath(folder: folder)
        
        let filePath =  "\(resourceFolder)\(path.stringByDeletingLastPathComponent)"
        
        return "\(filePath)/\(path.lastPathComponent).\(fileExt)"
    }
    
    static func getSynthesisfolderPath(_ systemFolder: String? = nil, 
                                folder: String? = nil) -> String {
        // 存放至 系统沙盒某目录
        let boxFolder = if let systemFolder { systemFolder }
        else { FileManager.cachesPath ?? "" }
        
        // 是否在系统下 建立指定文件夹
        let resourceFolder = if let folder { boxFolder + "/\(folder)" }
        else { boxFolder }
        return resourceFolder
        
    }
}
