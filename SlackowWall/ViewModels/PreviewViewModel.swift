//
// Created by Dominic Thompson on 1/18/23.
//

import SwiftUI
import ScriptingBridge

class PreviewViewModel: ObservableObject {

    @Published var lockedInstances: [pid_t] = []
    @Published var hoveredInstance: Int?
    @Published var keyPressed: Character?

    @MainActor func openInstance(idx: Int) {
        if (NSApplication.shared.isActive) {
            let pid = getInstanceProcess(idx: idx)
            writePid(pid: pid)
            DispatchQueue.global(qos: .background).async {
                let systemEvents = SBApplication(bundleIdentifier: "com.apple.systemevents")!
                if systemEvents.isRunning {
                    // Your AppleScript code to interact with System Events goes here
                } else {
                    // System Events is not running, so activate it and then execute AppleScript commands
                    systemEvents.activate()
                    // Your AppleScript code to interact with System Events goes here
                }
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
                } else {
                    print("Failed to send apple script")
                }
            }
            print("pressed: \(pid) #(\(idx))")
            lockedInstances.removeAll { $0 == pid }
        }
    }
    
    func lockInstance(idx: Int) {
        let pid = getInstanceProcess(idx: idx)
        if !lockedInstances.contains(pid) {
            withAnimation {
                lockedInstances.append(pid)
                SoundManager.shared.playSound(sound: "lock")
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
            default: return
            }
            keyPressed = nil
        }
    }

    private func writePid(pid: pid_t) {
        let filePath = "/Users/Shared/slackowwall.txt"
        let fileContents = "\(UUID.init()):\(pid)"
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: filePath) {
            let success = fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
            if !success {
                print("Failed to create file at path: \(filePath)")
            }
        }

        do {
            try fileContents.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Error writing to file: \(error)")
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
        return ShortcutManager.shared.states[idx].pid
    }
}
