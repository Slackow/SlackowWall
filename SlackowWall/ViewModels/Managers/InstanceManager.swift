//
// Created by Kihron on 1/18/23.
//

import SwiftUI


class InstanceManager: ObservableObject {
    @Published var hoveredInstance: TrackedInstance? = nil
    @Published var keyPressed: Character? = nil
    
    @Published var isStopping = false
    @Published var moving = false
    
    static let shared = InstanceManager()
    
    init() {

    }
    
    @MainActor func openInstance(instance: TrackedInstance) {
        if (NSApplication.shared.isActive) {
            if ProfileManager.shared.profile.checkStateOutput {
                let instanceInfo = instance.info
                instanceInfo.updateState(force: true)
                
                if instanceInfo.state != InstanceStates.paused && instanceInfo.state != InstanceStates.unpaused {
                    instance.lock()
                    return
                }
            }
            
            switchToInstance(instance: instance)
            instance.unlock()
        }
    }
    
    func hideWindows(_ targetPIDs: [pid_t]) {
        for pid in targetPIDs {
            let app = AXUIElementCreateApplication(pid)
            var error: AXError = AXError.success
            error = AXUIElementSetAttributeValue(app, kAXHiddenAttribute as CFString, kCFBooleanTrue)
            if error != .success {
                LogManager.shared.appendLog("Error setting visibility attribute for \(pid): \(error)")
            }
        }
    }
    
    func focusWindow(_ targetPID: pid_t) {
        NSRunningApplication(processIdentifier: targetPID)?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }
    
    func switchToInstance(instance: TrackedInstance) {
        guard let windowID = instance.windowID else { return }
        let pid = instance.pid
        
        OBSManager.shared.writeWID(windowID: windowID)
        LogManager.shared.appendLog("Pressed: \(pid) #(\(instance.instanceNumber))")
        
        Task {
            LogManager.shared.appendLog("Switching...")
            if ProfileManager.shared.profile.shouldHideWindows {
                let pids = TrackingManager.shared.trackedInstances.map({ $0.pid }).filter({$0 != pid})
                hideWindows(pids)
            }
            ShortcutManager.shared.resizeBase(pid: pid)
            focusWindow(pid)
            
            ShortcutManager.shared.sendEscape(pid: pid)
            
            if ProfileManager.shared.profile.f1OnJoin {
                ShortcutManager.shared.sendF1(pid: pid)
            }
            
            instance.info.checkState = .NONE
            LogManager.shared.appendLog("Switched to instance")
        }
    }
    
    func copyMods() {
        guard let statePath =  TrackingManager.shared.trackedInstances.map({ $0.info }).first?.statePath else { return }
        let src = URL(filePath: statePath).deletingLastPathComponent().appendingPathComponent("mods")
        let fileManager = FileManager.default
        
        TrackingManager.shared.trackedInstances.map({ $0.info }).dropFirst().forEach {
            let dst = URL(filePath: $0.statePath).deletingLastPathComponent().appendingPathComponent("mods")
            
            print("Copying all from", src.path, "to", dst.path)
            
            do {
                if fileManager.fileExists(atPath: dst.path) {
                    try fileManager.removeItem(at: dst)
                }
                // Create the destination directory
                try fileManager.createDirectory(at: dst, withIntermediateDirectories: true, attributes: nil)
                
                // Get the list of items in the source directory
                let items = try fileManager.contentsOfDirectory(atPath: src.path)
                
                // Copy each item from the source to the destination
                for item in items {
                    let srcItem = src.appendingPathComponent(item)
                    let dstItem = dst.appendingPathComponent(item)
                    try fileManager.copyItem(at: srcItem, to: dstItem)
                }
            } catch { print(error.localizedDescription) }
        }
        
        TrackingManager.shared.killAll()
    }
    
    @MainActor func handleKeyEvent(instance: TrackedInstance) {
        let pid = instance.pid
        
        if keyPressed == "t" {
            resetAllUnlocked()
            keyPressed = nil
            return
        }
        
        if hoveredInstance == nil {
            keyPressed = nil
            return
        }
        
        if hoveredInstance == instance {
            switch keyPressed {
                case "r": openInstance(instance: instance)
                case "e": resetInstance(instance: instance)
                case "f": enterAndResetUnlocked(instance: instance)
                case "p": ShortcutManager.shared.sendF3Esc(pid: pid)
                case "c": instance.toggleLock()
                case "u": ShortcutManager.shared.globalReset()
                default: return
            }
            keyPressed = nil
        }
    }
    
    @MainActor private func enterAndResetUnlocked(instance: TrackedInstance) {
        let pid = instance.pid
        openInstance(instance: instance)
        for instance in TrackingManager.shared.trackedInstances {
            if instance.pid != pid && canReset(instance: instance) {
                resetInstance(instance: instance)
            }
        }
    }
    
    private func canReset(instance: TrackedInstance) -> Bool {
        if instance.isLocked { return false }
        if !ProfileManager.shared.profile.checkStateOutput { return true }
        let info = instance.info
        info.updateState(force: true)
        return info.state != InstanceStates.waiting && info.state != InstanceStates.generating
    }
    
    private func resetAllUnlocked() {
        LogManager.shared.appendLog("Reset all possible")
        for instance in TrackingManager.shared.trackedInstances {
            if canReset(instance: instance) {
                resetInstance(instance: instance)
            } else {
                LogManager.shared.appendLog("Did not reset: \(instance.pid), State: \(instance.info.state)")
            }
        }
    }
    
    func resetInstance(instance: TrackedInstance) {
        let info = instance.info
        info.checkState = .GENNING
        ShortcutManager.shared.sendReset(pid: instance.pid)
        ShortcutManager.shared.playResetSound()
        instance.unlock()
    }
    
    func stopAll() {
        isStopping = true
        
        Task {
            await ScreenRecorder.shared.stop()
            TrackingManager.shared.killAll()
        }
    }
    
    func move(forward: Bool, direct: Bool = false) {
        moving = true
        Task {
            let xOff = (ProfileManager.shared.profile.moveXOffset ?? 0) * (forward ? 1 : -1)
            let yOff = (ProfileManager.shared.profile.moveYOffset ?? 0) * (forward ? 1 : -1)
            let pids = TrackingManager.shared.trackedInstances.map { $0.pid }
            let width = ProfileManager.shared.profile.setWidth ?? 0
            let height = ProfileManager.shared.profile.setHeight ?? 0
            let setSize = width > 0 && height > 0
            
            if (xOff == 0 && yOff == 0 && !setSize) || pids.isEmpty {
                DispatchQueue.main.async { self.moving = false }
                return
            }
            
            if setSize {
                DispatchQueue.main.async {
                    CaptureGrid.shared.showInfo = false
                }
                
                await ScreenRecorder.shared.stop(removeStreams: true)
            }
            
            for pid in pids {
                let appRef = AXUIElementCreateApplication(pid)
                var value: AnyObject?
                if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success, let windows = value as? [AXUIElement] {
                    for window in windows {
                        var titleValue: AnyObject?
                        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
                        if let title = titleValue as? String, title != "Window" {
                            var newPosition = direct ? CGPoint(x: CGFloat(xOff), y: CGFloat(yOff)) : CGPoint(x: CGFloat(xOff), y: CGFloat(yOff))
                            var newSize = CGSize(width: CGFloat(width), height: CGFloat(height))
                            
                            if let positionRef = AXValueCreate(AXValueType.cgPoint, &newPosition), let sizeRef = AXValueCreate(AXValueType.cgSize, &newSize) {
                                AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionRef)
                                if setSize {
                                    AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeRef)
                                }
                            }
                        }
                    }
                }
            }
            
            if setSize {
                await ScreenRecorder.shared.resetAndStartCapture()
            }
            
            DispatchQueue.main.async {
                self.moving = false
            }
        }
    }
}
