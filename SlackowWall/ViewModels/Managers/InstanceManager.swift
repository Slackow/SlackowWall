//
// Created by Kihron on 1/18/23.
//

import SwiftUI


class InstanceManager: ObservableObject {
    @AppStorage("rows") var rows: Int = AppDefaults.rows
    @AppStorage("alignment") var alignment: Alignment = AppDefaults.alignment
    @AppStorage("f1OnJoin") var f1OnJoin: Bool = false
    @AppStorage("onlyOnFocus") var onlyOnFocus: Bool = true
    
    @AppStorage("moveXOffset") var moveXOffset: String = "0"
    @AppStorage("moveYOffset") var moveYOffset: String = "0"

    @Published var lockedInstances: Int64 = 0
    @Published var hoveredInstance: Int?
    @Published var keyPressed: Character?
    
    @Published var isActive: Bool = true
    @Published var moving = false
    
    static let shared = InstanceManager()
    
    init() {
        
    }

    @MainActor func openInstance(idx: Int) {
        if (NSApplication.shared.isActive) {
            switchToInstance(idx: idx)
            lockedInstances &= ~(1 << idx)
        }
    }
    
    func switchToInstance(idx: Int) {
        let pid = getInstanceProcess(idx: idx)
        let _ = OBSManager.shared.writeWID(idx: idx + 1)
        print("User opened")
        Task {
            ShortcutManager.shared.prioritize(instNum: idx)
            print("Switching Window")
            let pids = ShortcutManager.shared.instanceIDs.filter {$0 != pid}.map {"\($0)"}.joined(separator: ",")
            let script = """
                tell application "System Events"
                    repeat with pid in [\(pids)]
                        set visible of (first process whose unix id is pid) to false
                    end repeat
                    set frontmost of the first process whose unix id is \(pid) to true
                end tell
                """
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
                if error != nil {
                    for (key, value) in error! {
                        print("\(key): \(value)")
                    }
                }
                ShortcutManager.shared.sendEscape(pid: pid)
                if self.f1OnJoin {
                    ShortcutManager.shared.sendF1(pid: pid)
                    print("Sent f1!!")
                }
                ShortcutManager.shared.states[idx].checkState = .NONE
            } else {
                print("Failed to send apple script")
            }
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
        let state = ShortcutManager.shared.states[idx]
        let _ = state.updateState(force: true)
        return state.state != WAITING && state.state != GENERATING
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

    func getInstanceProcess(idx: Int) -> pid_t {
        return ShortcutManager.shared.states[idx].pid
    }
    
    func move(forward: Bool, direct: Bool = false) {
        moving = true
        Task {
            let xOff = "\(direct ? "" : "x+")\((Int32(moveXOffset) ?? 0) * (forward ? 1 : -1))"
            let yOff = "\(direct ? "" : "y+")\((Int32(moveYOffset) ?? 0) * (forward ? 1 : -1))"
            let pids = ShortcutManager.shared.instanceIDs.map({"\($0)"}).joined(separator: ",")
            if (xOff == "x+0" && yOff == "y+0") || pids.isEmpty { moving = false;return }
            let fullScript = """
                tell application "System Events"
                    repeat with pid in [\(pids)]
                        repeat with aWindow in (every window of (first process whose unix id is pid))
                            if name of aWindow is not "Window" then \(direct ? "" : "\nset {x, y} to position of aWindow")
                                set position of aWindow to {\(xOff), \(yOff)}
                            end if
                        end repeat
                    end repeat
                end tell
                """
            
            print("\(fullScript)")
            // Execute the AppleScript
            if let appleScript = NSAppleScript(source: fullScript) {
                var errorDict: NSDictionary? = nil
                appleScript.executeAndReturnError(&errorDict)
                if let error = errorDict {
                    print("AppleScript Execution Error: \(error)")
                }
            }
            moving = false
        }
    }
}
