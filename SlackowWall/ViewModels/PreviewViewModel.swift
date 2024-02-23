//
// Created by Kihron on 1/18/23.
//

import SwiftUI


class PreviewViewModel: ObservableObject {

    @Published var lockedInstances: Int64 = 0
    @Published var hoveredInstance: Int?
    @Published var keyPressed: Character?
    
    @AppStorage("f1OnJoin") var f1OnJoin: Bool = false

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
            print("Switching Window")
            let script = "tell application \"System Events\" to set frontmost of the first process whose unix id is \(pid) to true"
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
}
