//
//  TrackedInstance.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import ScreenCaptureKit
import SwiftUI

class TrackedInstance: ObservableObject, Identifiable, Hashable, Equatable, @unchecked Sendable {
    let id: UUID

    let pid: pid_t
    var windowID: CGWindowID?
    let instanceNumber: Int

    let info: InstanceInfo
    var stream: InstanceStream
    var eyeProjectorStream: InstanceStream
    var eCountProjectorStream: InstanceStream

    @Published var isLocked: Bool
    @Published var wasClosed: Bool
    @Published var ninbotResults: NinjabrainAdjuster.Results?
    @Published var ninbotIsChecking: Bool
    @Published var ninbotCheckError: String?

    init(pid: pid_t, instanceNumber: Int) {
        self.id = UUID()
        self.pid = pid
        self.instanceNumber = instanceNumber
        self.info = TrackedInstance.calculateInstanceInfo(pid: pid)
        self.stream = InstanceStream()
        self.eyeProjectorStream = InstanceStream()
        self.eCountProjectorStream = InstanceStream()
        self.isLocked = false
        self.wasClosed = false
        self.ninbotResults = nil
        self.ninbotIsChecking = false
        self.ninbotCheckError = nil
    }

    var name: Substring {
        let path = self.info.path
        var result = path.split(separator: "/").last ?? "??"
        if result == "minecraft" || result == ".minecraft" {
            result = path.split(separator: "/").dropLast(1).last ?? "??"
        }
        return result == "Application Support" ? "Minecraft" : result
    }

    var isReady: Bool {
        if hasMod(.stateOutput) {
            return info.state == .paused || info.state == .unpaused
        } else {
            return true
        }
    }

    var settings: InstanceSettings {
        info.settings
    }

    func hasMod(_ knownMod: KnownMod) -> Bool {
        return info.hasMod(knownMod)
    }

    enum KnownMod: String {
        case retino = "retino"
        case standardSettings = "standardsettings"
        case stateOutput = "state-output"
        case boundless = "boundlesswindow"
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

    func scheduleNinbotCheck(delay: TimeInterval = 1.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if self?.ninbotResults == nil {
                self?.refreshNinbotStatus()
            }
        }
    }

    func refreshNinbotStatus() {
        guard !ninbotIsChecking else { return }
        ninbotIsChecking = true
        ninbotCheckError = nil

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                let results = try NinjabrainAdjuster.get(instance: self)
                await MainActor.run {
                    self.ninbotResults = results
                    self.ninbotIsChecking = false
                }
            } catch {
                await MainActor.run {
                    self.ninbotResults = nil
                    self.ninbotCheckError = error.localizedDescription
                    self.ninbotIsChecking = false
                }
                LogManager.shared.appendLog("Failed to check NinjabrainBot settings:", error)
            }
        }
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
