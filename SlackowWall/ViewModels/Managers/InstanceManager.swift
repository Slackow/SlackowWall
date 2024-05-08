//
// Created by Kihron on 1/18/23.
//

import SwiftUI
import ApplicationServices

class InstanceManager: ObservableObject {
    @AppStorage("rows") var rowsSetting: Int = AppDefaults.rows {
        didSet {
            rows = rowsSetting
        }
    }
    @AppStorage("alignment") var alignmentSetting: Alignment = AppDefaults.alignment {
        didSet {
            alignment = alignmentSetting
        }
    }
    
    var rows: Int = 8
    var alignment: Alignment = .horizontal
    @AppStorage("shouldHideWindows") var shouldHideWindows = true
    @AppStorage("showInstanceNumbers") var showInstanceNumbers = true
    @AppStorage("forceAspectRatio") var forceAspectRatio = false
    @AppStorage("smartGrid") var smartGrid = true
    
    @AppStorage("moveXOffset") var moveXOffset: Int = 0
    @AppStorage("moveYOffset") var moveYOffset: Int = 0
    
    @AppStorage("setWidth") var setWidth: Int? = nil
    @AppStorage("setHeight") var setHeight: Int? = nil
    
    // Behavior
    @AppStorage("f1OnJoin") var f1OnJoin: Bool = false
    @AppStorage("fullscreen") var fullscreen: Bool = false
    @AppStorage("onlyOnFocus") var onlyOnFocus: Bool = true
    @AppStorage("checkStateOutput") var checkStateOutput: Bool = false
    
    @AppStorage("resetWidth") var resetWidth: Int? = nil
    @AppStorage("resetHeight") var resetHeight: Int? = nil
    @AppStorage("baseWidth") var baseWidth: Int? = nil
    @AppStorage("baseHeight") var baseHeight: Int? = nil
    @AppStorage("wideWidth") var wideWidth: Int? = nil
    @AppStorage("wideHeight") var wideHeight: Int? = nil

    @Published var lockedInstances: Int64 = 0
    @Published var hoveredInstance: Int?
    @Published var keyPressed: Character?
    
    @Published var isActive: Bool = true
    @Published var isStopping = false
    @Published var moving = false
    
    static let shared = InstanceManager().onStart()
    
    private func onStart() -> Self {
        rows = rowsSetting
        alignment = alignmentSetting
        return self
    }
    
    init() {
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
            if InstanceManager.shared.shouldHideWindows {
                let pids = ShortcutManager.shared.instanceIDs.filter {$0 != pid}
                hideWindows(pids)
            }
            ShortcutManager.shared.resizeBase(pid: pid)
            focusWindow(pid)
            
            ShortcutManager.shared.sendEscape(pid: pid)
            if self.f1OnJoin {
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
            case "0": ShortcutManager.shared.globalReset()
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
        if !checkStateOutput { return true }
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
    
    func invertGridLayout() {
        let instanceCount = ShortcutManager.shared.instanceIDs.count
        let maximumRows = 9
        let minimumRows = 1
        
        var newRows = (instanceCount + rows - 1) / rows
        newRows = max(minimumRows, min(newRows, maximumRows))
        
        rows = newRows
        alignment = alignment == .vertical ? .horizontal : .vertical
    }
    
    func stopAll() {
        isStopping = true
        ShortcutManager.shared.killAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exit(0)
        }
    }

    func getInstanceProcess(idx: Int) -> pid_t {
        return ShortcutManager.shared.states[idx].pid
    }

    func move(forward: Bool, direct: Bool = false) {
        moving = true
        Task {
            let xOff = moveXOffset * (forward ? 1 : -1)
            let yOff = moveYOffset * (forward ? 1 : -1)
            let pids = ShortcutManager.shared.instanceIDs
            let width = setWidth ?? 0
            let height = setHeight ?? 0
            let setSize = width > 0 && height > 0

            if (xOff == 0 && yOff == 0 && !setSize) || pids.isEmpty {
                DispatchQueue.main.async { self.moving = false }
                return
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
