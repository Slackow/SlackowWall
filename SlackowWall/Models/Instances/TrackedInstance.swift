//
//  TrackedInstance.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI
import ScreenCaptureKit
import Network

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
        if let contents = FileManager.default.contents(atPath: "\(path)/boundless_port.txt"),
            !contents.isEmpty,
           let port = String(data: contents, encoding: .utf8)
        {
            data.port = UInt16(port) ?? 0
        }
        LogManager.shared
            .appendLog("Added Instance \(pid)")
            .appendLog("Path: \(data.path)")
            .appendLog("Version: \(data.version)")
            .appendLog("Port: \(data.port)")
            .appendLogNewLine()
        return data
    }
    
    func sendResizeCommand(x: Int?, y: Int?, width: Int?, height: Int?) {
        let port = self.info.port
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            LogManager.shared.appendLog("Invalid port value: \(port)")
            return
        }
        func un(_ n: Int?) -> String { return n?.description ?? "-" }
        let command = "set \(un(x)) \(un(y)) \(un(width)) \(un(height))\n"
        
        // Create an NWConnection to localhost on the instance's port.
        let connection = NWConnection(host: .init("127.0.0.1"), port: nwPort, using: .tcp)
        connection.stateUpdateHandler = { state in
            LogManager.shared.appendLog("Connection state: \(state)")
        }
        connection.start(queue: DispatchQueue.global())
        connection.send(content: command.data(using: .utf8), completion: .contentProcessed({ error in
           if let error {
               LogManager.shared.appendLog("Error sending resize command: \(error)")
               connection.cancel()
               return
           } else {
               LogManager.shared.appendLog("Resize command sent: \(command.trimmingCharacters(in: .newlines))")
           }
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, context, isComplete, error in
               if let error {
                   LogManager.shared.appendLog("Receive error: \(error)")
               } else if let data, let response = String(data: data, encoding: .utf8) {
                   LogManager.shared.appendLog("Received response: \(response.trimmingCharacters(in: .newlines))")
               } else {
                   LogManager.shared.appendLog("Connection closed by remote")
               }
               
               // 3) Close once we’ve gotten (or failed to get) that response
               connection.cancel()
           }
        }))
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
