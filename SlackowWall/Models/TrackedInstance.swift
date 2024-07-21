//
//  TrackedInstance.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI

class TrackedInstance: ObservableObject, Hashable, Equatable {
    let pid: pid_t
    var windowID: CGWindowID?
    let instanceNumber: Int
    
    @Published var info: InstanceInfo
    @Published var capturePreview: CapturePreview
    @Published var captureRect: CGSize
    
    @Published var isLocked: Bool
    
    init(pid: pid_t, instanceNumber: Int) {
        self.pid = pid
        self.instanceNumber = instanceNumber
        self.info = TrackedInstance.calculateInstanceInfo(pid: pid)
        self.capturePreview = CapturePreview()
        self.captureRect = .zero
        self.isLocked = false
    }
    
    private static func calculateInstanceInfo(pid: pid_t) -> InstanceInfo {
        let data = InstanceInfo(pid: pid)
        if let args = Utils.processArguments(pid: pid) {
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
        
        objectWillChange.send()
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
            objectWillChange.send()
        }
    }
    
    func unlock() {
        if isLocked {
            isLocked = false
            LogManager.shared.appendLog("Unlocking instance \(instanceNumber)")
            objectWillChange.send()
        }
    }
    
    static func == (lhs: TrackedInstance, rhs: TrackedInstance) -> Bool {
        return lhs.pid == rhs.pid && lhs.instanceNumber == rhs.instanceNumber
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
        hasher.combine(instanceNumber)
    }
}
