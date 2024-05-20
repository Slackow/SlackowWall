//
// Created by Kihron on 1/18/23.
//

import SwiftUI
import Combine

class InstanceManager: ObservableObject {
    @Published var screenSize: CGSize?
    
    @Published var lockedInstances: Int64 = 0
    @Published var hoveredInstance: Int? = nil
    @Published var keyPressed: Character? = nil
    
    @Published var isActive: Bool = true
    @Published var isStopping = false
    @Published var moving = false
    
    @Published var animateGrid: Bool = false
    @Published var showInfo: Bool = false
    
    static let shared = InstanceManager()
    
    private var cancellable: AnyCancellable?
    
    init() {
        self.screenSize = NSScreen.main?.visibleFrame.size
        setupScreenChangeNotification()
    }
    
    private func setupScreenChangeNotification() {
        cancellable = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.screenSize = NSScreen.main?.visibleFrame.size
            }
    }

    @MainActor func openInstance(idx: Int) {
        if (NSApplication.shared.isActive) {
            switchToInstance(idx: idx)
            unlockInstance(idx: idx)
        }
    }

    func hideWindows(_ targetPIDs: [pid_t]) {
        for pid in targetPIDs {
            let app = AXUIElementCreateApplication(pid)
            var error: AXError = AXError.success
            error = AXUIElementSetAttributeValue(app, kAXHiddenAttribute as CFString, kCFBooleanTrue)
            if error != .success {
                print("Error setting visibility attribute for PID \(pid): \(error)")
            }
        }
    }
    
    func focusWindow(_ targetPID: pid_t) {
        NSRunningApplication(processIdentifier: targetPID)?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }

    
    func switchToInstance(idx: Int) {
        let pid = getInstanceProcess(idx: idx)
        OBSManager.shared.writeWID(idx: idx + 1)
        print("User opened")
        Task {
            print("Switching Window")
            if ProfileManager.shared.profile.shouldHideWindows {
                let pids = ShortcutManager.shared.instanceIDs.filter {$0 != pid}
                hideWindows(pids)
            }
            ShortcutManager.shared.resizeBase(pid: pid)
            focusWindow(pid)
            
            ShortcutManager.shared.sendEscape(pid: pid)
            if ProfileManager.shared.profile.f1OnJoin {
                ShortcutManager.shared.sendF1(pid: pid)
                print("Sent f1!!")
            }
            ShortcutManager.shared.states[idx].checkState = .NONE
            
            print("Switched")
        }
        print("pressed: \(pid) #(\(idx))")
    }
    
    func lockInstance(idx: Int) {
        let oldLocked = lockedInstances
        lockedInstances ^= 1 << idx
        
        if oldLocked < lockedInstances {
            withAnimation {
                SoundManager.shared.playSound(sound: "lock")
            }
            print("Locking \(idx)")
        } else {
            print("Unlocking \(idx)")
        }
    }
    
    func copyMods() {
        ShortcutManager.shared.killAll()
        guard let statePath = ShortcutManager.shared.states.first?.statePath else { return }
        let src = URL(filePath: statePath).deletingLastPathComponent().appendingPathComponent("mods")
        let f = FileManager.default
        ShortcutManager.shared.states.dropFirst().forEach {
            let dst = URL(filePath: $0.statePath).deletingLastPathComponent().appendingPathComponent("mods")
            
            print("copying all from", src.path, "to", dst.path)
            
            do {
                if f.fileExists(atPath: dst.path) {
                    try f.removeItem(at: dst)
                }
                // Create the destination directory
                try f.createDirectory(at: dst, withIntermediateDirectories: true, attributes: nil)
                
                // Get the list of items in the source directory
                let items = try f.contentsOfDirectory(atPath: src.path)
                
                // Copy each item from the source to the destination
                for item in items {
                    let srcItem = src.appendingPathComponent(item)
                    let dstItem = dst.appendingPathComponent(item)
                    try f.copyItem(at: srcItem, to: dstItem)
                }
            } catch { print(error.localizedDescription) }
        }
    }

    @MainActor func handleKeyEvent(idx: Int) {
        let pid = getInstanceProcess(idx: idx)

        if keyPressed == "t" {
            resetAllUnlocked()
            keyPressed = nil
            hoveredInstance = nil
        }

        if hoveredInstance == nil {
            keyPressed = nil
        }

        if hoveredInstance == idx {
            switch keyPressed {
            case "r": openInstance(idx: idx)
            case "e": ShortcutManager.shared.resetInstance(pid: pid)
            case "f": enterAndResetUnlocked(idx: idx)
            case "p": ShortcutManager.shared.sendF3Esc(pid: pid)
            case "c": lockInstance(idx: idx)
            case "u": ShortcutManager.shared.globalReset()
            default: return
            }
            keyPressed = nil
        }
    }

    @MainActor private func enterAndResetUnlocked(idx: Int) {
        let pid = getInstanceProcess(idx: idx)
        let instanceIDs = ShortcutManager.shared.instanceIDs
        openInstance(idx: idx)
        var idx = 0
        for instance in instanceIDs {
            if instance != pid && canReset(idx: idx) {
                ShortcutManager.shared.resetInstance(pid: instance)
            }
            idx += 1
        }
    }
    
    @inline(__always) public func isLocked(idx: Int) -> Bool {
        return (lockedInstances & (1 << idx)) != 0
    }
    
    @inline(__always) private func canReset(idx: Int) -> Bool {
        if isLocked(idx: idx) { return false }
        if !ProfileManager.shared.profile.checkStateOutput { return true }
        let state = ShortcutManager.shared.states[idx]
        state.updateState(force: true)
        return state.state != InstanceStates.waiting && state.state != InstanceStates.generating
    }
    @inline(__always) public func unlockInstance(idx: Int) {
        lockedInstances &= ~(1 << idx)
    }

    private func resetAllUnlocked() {
        print("\n\n\n\n")
        let instanceIDs = ShortcutManager.shared.instanceIDs
        var idx = 0
        for instance in instanceIDs {
            if canReset(idx: idx) {
                ShortcutManager.shared.resetInstance(pid: instance)
            } else {
                print("Did not reset: \(ShortcutManager.shared.states[idx].state)")
            }
            idx += 1
        }
        print("Reset All possible")
    }
    
    func showInstanceInfo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.smooth) {
                self.showInfo = true
            }
        }
    }
    
    func handleGridAnimation(value: Int) {
        if value > 0 {
            animateGrid = true
            
            let delay = (Double(value) * 0.07) + 0.07
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.animateGrid = false
            }
        } else {
            animateGrid = false
        }
    }
    
    func stopAll() {
        isStopping = true
        
        Task {
            await ScreenRecorder.shared.stop()
            ShortcutManager.shared.killAll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                exit(0)
            }
        }
    }

    func getInstanceProcess(idx: Int) -> pid_t {
        return ShortcutManager.shared.states[idx].pid
    }

    func move(forward: Bool, direct: Bool = false) {
        moving = true
        Task {
            let xOff = (ProfileManager.shared.profile.moveXOffset ?? 0) * (forward ? 1 : -1)
            let yOff = (ProfileManager.shared.profile.moveYOffset ?? 0) * (forward ? 1 : -1)
            let pids = ShortcutManager.shared.instanceIDs
            let width = ProfileManager.shared.profile.setWidth ?? 0
            let height = ProfileManager.shared.profile.setHeight ?? 0
            let setSize = width > 0 && height > 0

            if (xOff == 0 && yOff == 0 && !setSize) || pids.isEmpty {
                DispatchQueue.main.async { self.moving = false }
                return
            }
            
            if setSize {
                DispatchQueue.main.async {
                    self.showInfo = false
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
