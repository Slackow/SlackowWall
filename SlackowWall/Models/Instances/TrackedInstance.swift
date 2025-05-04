//
//  TrackedInstance.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI
import ScreenCaptureKit

class TrackedInstance: ObservableObject, Identifiable, Hashable, Equatable {
    let id: UUID
    
    let pid: pid_t
    var windowID: CGWindowID?
    let instanceNumber: Int
    
    var info: InstanceInfo
    var stream: InstanceStream
    
    @Published var isLocked: Bool
    @Published var wasClosed: Bool
    
    init(pid: pid_t, instanceNumber: Int) {
        self.id = UUID()
        self.pid = pid
        self.instanceNumber = instanceNumber
        self.info = TrackedInstance.calculateInstanceInfo(pid: pid)
        self.stream = InstanceStream()
        self.isLocked = false
        self.wasClosed = false
    }
    
    var isReady: Bool {
        if ProfileManager.shared.profile.checkStateOutput {
            return info.state == InstanceStates.paused || info.state == InstanceStates.unpaused
        } else {
            return true
        }
    }
    
    func recalculateInstanceInfo() {
        self.info = TrackedInstance.calculateInstanceInfo(pid: pid)
    }
    
    private static func calculateInstanceInfo(pid: pid_t) -> InstanceInfo {
        let data = InstanceInfo(pid: pid)
        var path = ""
        var version = ""
        if let args = Utilities.processArguments(pid: pid) {
            // Vanilla Launcher
            if let vanillaIdx = args.firstIndex(of: "--gameDir") {
                path = args[safe: vanillaIdx + 1] ?? ""
                if let vanillaVersionIdx = args.firstIndex(of: "--version") {
                    version = args[safe: vanillaVersionIdx + 1] ?? ""
                    let prefix = try? /fabric-loader-\d+\.\d+(?:\.\d+)?-/.prefixMatch(in: version)
                    version = prefix.map {String(version.dropFirst($0.count))} ?? version
                }
            // Prism/MultiMC etc
            } else if let nativesArg = args.first(where: { $0.starts(with: "-Djava.library.path=") }) {
                let arg = nativesArg.dropLast("/natives".count).dropFirst("-Djava.library.path=".count)
                let possiblePaths = ["\(arg)/minecraft", "\(arg)/.minecraft"]
                path = possiblePaths.first(where: FileManager.default.fileExists) ?? ""
                let regex = #/minecraft-([\d.]+?)-client\.jar|intermediary/([\d.]+?)/intermediary/#
                let matches = args.compactMap { try? regex.firstMatch(in: $0) }
                if let match = matches.first {
                    version = String(match.1 ?? match.2 ?? "")
                }
            }
        }
        data.path = path
        data.version = version
        // default to trying to use boundless if can't read these properties correctly
        if let boundlessFile = getModifiedTime("\(path)/boundless_port.txt"),
           let logFile = getCreatedTime("\(path)/logs/latest.log"),
           boundlessFile < logFile {
            LogManager.shared.appendLog("Found old boundless_port.txt, mod not present.")
            let port = FileManager.default.contents(atPath: "\(path)/boundless_port.txt")
                .flatMap {String(data: $0, encoding: .utf8)}
            LogManager.shared.appendLog("Would have used port: \(port ?? "N/A")")
            data.port = 3
        } else if let contents = FileManager.default.contents(atPath: "\(path)/boundless_port.txt"),
           !contents.isEmpty,
           let port = String(data: contents, encoding: .utf8),
           let port = UInt16(port)
        {
            data.port = port
        }
        LogManager.shared
            .appendLog("Added Instance \(pid)")
            .appendLog("Path: \(data.path)")
            .appendLog("Version: \(data.version)")
            .appendLog("Port: \(data.port)")
            .appendLogNewLine()
        return data
    }
    
    private static func getModifiedTime(_ filePath: String, fileManager: FileManager = FileManager.default) -> Date? {
        try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.modificationDate] as? Date
    }
    
    private static func getCreatedTime(_ filePath: String, fileManager: FileManager = FileManager.default) -> Date? {
        try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.creationDate] as? Date
    }
    
    func updateInstanceInfo() {
        self.info.updateState(force: true)
    }
    
    func toggleLock() {
        let wasLocked = isLocked
        isLocked.toggle()
        
        if wasLocked != isLocked {
            if isLocked {
                SoundManager.shared.playSound(sound: "lock")
                LogManager.shared.appendLog("Locking instance \(instanceNumber)")
            } else {
                LogManager.shared.appendLog("Unlocking instance \(instanceNumber)")
            }
        }
    }
    
    func lock() {
        if !isLocked {
            isLocked = true
            SoundManager.shared.playSound(sound: "lock")
            LogManager.shared.appendLog("Locking instance \(instanceNumber)")
        }
    }
    
    func unlock() {
        if isLocked {
            isLocked = false
            LogManager.shared.appendLog("Unlocking instance \(instanceNumber)")
        }
    }
    
    static func == (lhs: TrackedInstance, rhs: TrackedInstance) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(pid)
        hasher.combine(instanceNumber)
    }
}
