//
//  TrackedInstance.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import ScreenCaptureKit
import SwiftUI

class TrackedInstance: ObservableObject, Identifiable, Hashable, Equatable {
    let id: UUID

    let pid: pid_t
    var windowID: CGWindowID?
    let instanceNumber: Int

    let info: InstanceInfo
    var stream: InstanceStream
    var eyeProjectorStream: InstanceStream

    @Published var isLocked: Bool
    @Published var wasClosed: Bool

    init(pid: pid_t, instanceNumber: Int) {
        self.id = UUID()
        self.pid = pid
        self.instanceNumber = instanceNumber
        self.info = TrackedInstance.calculateInstanceInfo(pid: pid)
        self.stream = InstanceStream()
        self.eyeProjectorStream = InstanceStream()
        self.isLocked = false
        self.wasClosed = false
    }

    var name: Substring {
        let result = self.info.path.split(separator: "/").dropLast(1).last ?? "??"
        return result == "Application Support" ? "Minecraft" : result
    }

    var isReady: Bool {
        if checkStateOutput {
            return info.state == InstanceStates.paused || info.state == InstanceStates.unpaused
        } else {
            return true
        }
    }

    var checkStateOutput: Bool {
        return info.mods.map(\.id).contains("state-output")
    }

    private static func calculateInstanceInfo(pid: pid_t) -> InstanceInfo {
        var path = ""
        var version = ""
        if let args = Utilities.processArguments(pid: pid) {
            // Vanilla Launcher
            if let vanillaIdx = args.firstIndex(of: "--gameDir") {
                path = args[safe: vanillaIdx + 1] ?? ""
                if let vanillaVersionIdx = args.firstIndex(of: "--version") {
                    version = args[safe: vanillaVersionIdx + 1] ?? ""
                    let prefix = try? /fabric-loader-\d+\.\d+(?:\.\d+)?-/.prefixMatch(in: version)
                    version = prefix.map { String(version.dropFirst($0.count)) } ?? version
                }
                // Prism/MultiMC etc
            } else if let nativesArg = args.first(where: { $0.starts(with: "-Djava.library.path=") }
            ) {
                let arg = nativesArg.dropLast("/natives".count).dropFirst(
                    "-Djava.library.path=".count)
                let possiblePaths = ["\(arg)/minecraft", "\(arg)/.minecraft"]
                path = possiblePaths.first(where: FileManager.default.fileExists) ?? ""
                let regex = #/minecraft-([\d.]+?)-client\.jar|intermediary/([\d.]+?)/intermediary/#
                let matches = args.compactMap { try? regex.firstMatch(in: $0) }
                if let match = matches.first {
                    version = String(match.1 ?? match.2 ?? "")
                }
            }
        }
        let data = InstanceInfo(pid: pid, path: path, version: version)

        LogManager.shared
            .appendLog("Added Instance \(pid)")
            .logPath("Path: \(data.path)")
            .appendLog("Version: \(data.version)")
            .appendLogNewLine()
        return data
    }

    private static func getModifiedTime(
        _ filePath: String, fileManager: FileManager = FileManager.default
    ) -> Date? {
        try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.modificationDate]
            as? Date
    }

    private static func getCreatedTime(
        _ filePath: String, fileManager: FileManager = FileManager.default
    ) -> Date? {
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
