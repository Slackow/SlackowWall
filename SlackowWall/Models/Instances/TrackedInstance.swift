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
    
    @Published var info: InstanceInfo
    @Published var stream: InstanceStream
    
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
    
    private static func calculateInstanceInfo(pid: pid_t) -> InstanceInfo {
        let data = InstanceInfo(pid: pid)
        if let args = Utilities.processArguments(pid: pid) {
            if let nativesArg = args.first(where: { $0.starts(with: "-Djava.library.path=") }) {
                let arg = nativesArg.dropLast("/natives".count).dropFirst("-Djava.library.path=".count)
                data.statePath = "\(arg)/.minecraft/wpstateout.txt"
            }
        }
        return data
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
