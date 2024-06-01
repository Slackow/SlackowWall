//
//  LogManager.swift
//  SlackowWall
//
//  Created by Kihron on 5/27/24.
//

import Gzip
import SwiftUI

class LogManager {
    private let logDirectory = "/tmp/SlackowWall/"
    
    static let shared = LogManager()
    
    private var logPath: String {
        return logDirectory + "latest.log"
    }
    
    init() {
        createLogDirectory()
        createLogFile()
        prependSystemInfo()
        appendLogSection("Log Output")
    }
    
    private func createLogDirectory() {
        let fileManager = FileManager.default
        let logDirectoryURL = URL(fileURLWithPath: logDirectory)
        
        do {
            try fileManager.createDirectory(at: logDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create log directory: \(error)")
        }
    }
    
    private func createLogFile() {
        let fileManager = FileManager.default
        let logURL = URL(fileURLWithPath: logPath)
        
        if fileManager.fileExists(atPath: logPath) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: logPath)
                if let creationDate = attributes[.creationDate] as? Date {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                    let dateString = dateFormatter.string(from: creationDate)
                    let backupLogPath = logDirectory + "\(dateString).log"
                    let backupLogURL = URL(fileURLWithPath: backupLogPath)
                    
                    try fileManager.moveItem(at: logURL, to: backupLogURL)
                    
                    compressLogFile(at: backupLogURL)
                } else {
                    print("Failed to get creation date of log file")
                }
            } catch {
                print("Failed to rename log file: \(error)")
            }
        }
        
        // Create new log file
        fileManager.createFile(atPath: logPath, contents: nil, attributes: nil)
    }
    
    private func compressLogFile(at url: URL) {
        let fileManager = FileManager.default
        let sourceURL = url
        let destinationURL = sourceURL.appendingPathExtension("gz")
        
        do {
            let sourceData = try Data(contentsOf: sourceURL)
            let compressedData = try sourceData.gzipped(level: .bestCompression)
            
            try compressedData.write(to: destinationURL)
            try fileManager.removeItem(at: sourceURL)
            
            print("Successfully compressed log file to: \(destinationURL.path)")
        } catch {
            print("Failed to compress log file: \(error)")
        }
    }
    
    func appendLog(_ items: Any..., showInConsole: Bool = true, includeTimestamp: Bool = true) {
        let logURL = URL(fileURLWithPath: logPath)
        let message = items.map { String(describing: $0) }.joined(separator: " ")
        
        let timestamp: String
        if includeTimestamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss.SSS"
            timestamp = "[\(dateFormatter.string(from: Date()))] "
        } else {
            timestamp = ""
        }
        
        let messageWithNewline = timestamp + "- " + message + "\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            fileHandle.seekToEndOfFile()
            
            if let data = messageWithNewline.data(using: .utf8) {
                fileHandle.write(data)
            }
            
            fileHandle.closeFile()
            
            if showInConsole {
                print(message)
            }
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    func appendLogSection(_ title: String) {
        let logURL = URL(fileURLWithPath: logPath)
        let titleWithNewline = title + ":\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            fileHandle.seekToEndOfFile()
            
            if let data = titleWithNewline.data(using: .utf8) {
                fileHandle.write(data)
            }
            
            fileHandle.closeFile()
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    func appendLogNewLine() {
        let logURL = URL(fileURLWithPath: logPath)
        let newLine = "\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            fileHandle.seekToEndOfFile()
            
            if let data = newLine.data(using: .utf8) {
                fileHandle.write(data)
            }
            
            fileHandle.closeFile()
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    private func prependSystemInfo() {
        appendLogSection("System Information")
        
        // Get macOS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "macOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        appendLog(osVersionString, showInConsole: false, includeTimestamp: false)
        
        // Get hardware information
        var hwModel = ""
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        if size > 0 {
            var model = [CChar](repeating: 0, count: Int(size))
            sysctlbyname("hw.model", &model, &size, nil, 0)
            hwModel = String(cString: model)
        }
        appendLog("Hardware Model: \(hwModel)", showInConsole: false, includeTimestamp: false)
        
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        appendLog(String(format: "Memory: %.2f GB", Double(physicalMemory) / 1073741824.0), showInConsole: false, includeTimestamp: false)
        
        let processorCount = ProcessInfo.processInfo.processorCount
        appendLog("Processor Count: \(processorCount)", showInConsole: false, includeTimestamp: false)
        
        // Get app version
        if let appVersion = UpdateManager.shared.appVersion, let buildNumber = UpdateManager.shared.appBuild {
            appendLog("App Version: \(appVersion) (\(buildNumber))", showInConsole: false, includeTimestamp: false)
        } else {
            appendLog("App Version: Unknown", showInConsole: false, includeTimestamp: false)
        }
        
        appendLogNewLine()
    }
    
    func openLogFolder() {
        let logFolderURL = URL(fileURLWithPath: logDirectory)
        
        if FileManager.default.fileExists(atPath: logDirectory) {
            NSWorkspace.shared.open(logFolderURL)
        }
    }
    
    func openLatestLogInConsole() {
        let logFileURL = URL(fileURLWithPath: logPath)
        
        if FileManager.default.fileExists(atPath: logPath) {
            NSWorkspace.shared.open(logFileURL)
        }
    }
}
