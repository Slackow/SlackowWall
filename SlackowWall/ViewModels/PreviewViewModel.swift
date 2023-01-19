//
// Created by Dominic Thompson on 1/18/23.
//

import SwiftUI

class PreviewViewModel: ObservableObject {

    @Published var lockedInstances: [pid_t] = []
    @Published var hoveredInstance: Int?
    @Published var keyPressed: Character?

    @MainActor func openInstance(idx: Int) {
        if (NSApplication.shared.isActive) {
            let pid = getInstanceProcess(idx: idx)

            let script = "tell application \"System Events\" to set frontmost of the first process whose unix id is \(pid) to true"

            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
                ShortcutManager.shared.sendEscape(pid: pid)
            } else {
                print("Failed to send apple script")
            }

            print("pressed: \(pid) #(\(idx))")
        }
    }
    
    func lockInstance(idx: Int) {
        let pid = getInstanceProcess(idx: idx)
        if !lockedInstances.contains(pid) {
            withAnimation {
                lockedInstances.append(pid)
            }
            print("Locking \(pid)")
            print(lockedInstances)
        } else {
            lockedInstances.removeAll(where: { $0 == pid })
            print("Unlocking \(pid)")
            print(lockedInstances)
        }
    }

    @MainActor func handleKeyEvent(idx: Int) {
        let pid = getInstanceProcess(idx: idx)
        if hoveredInstance == idx {
            switch keyPressed {
                case "r": openInstance(idx: idx)
                case "e": ShortcutManager.shared.resetInstance(pid: pid)
                case "f": enterAndResetUnlocked(idx: idx)
                case "t": resetAllUnlocked()
                default: return
            }
            keyPressed = nil
        }
    }

    @MainActor private func enterAndResetUnlocked(idx: Int) {
        let pid = getInstanceProcess(idx: idx)
        let instanceIDs = ShortcutManager.shared.instanceIDs
        openInstance(idx: idx)
        for instance in instanceIDs {
            if instance != pid && !lockedInstances.contains(instance) {
                ShortcutManager.shared.resetInstance(pid: instance)
            }
        }
    }

    private func resetAllUnlocked() {
        let instanceIDs = ShortcutManager.shared.instanceIDs
        for instance in instanceIDs {
            if !lockedInstances.contains(instance) {
                ShortcutManager.shared.resetInstance(pid: instance)
            }
        }
    }

    func getInstanceProcess(idx: Int) -> pid_t {
        return ShortcutManager.shared.instanceIDs[idx]
    }
}
