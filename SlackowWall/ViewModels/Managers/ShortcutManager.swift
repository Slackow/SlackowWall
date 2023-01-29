//
//  ShortcutManager.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI
import KeyboardShortcuts
import ScreenCaptureKit
import AVFoundation

final class ShortcutManager: ObservableObject {
    @Published var instanceNums = [pid_t:Int]()
    @Published var instanceIDs = [pid_t]()
    @Published var states = [InstanceInfo]()

    static let shared = ShortcutManager()

    init() {
        KeyboardShortcuts.onKeyUp(for: .reset) { [self] in
            print("reset")
            let apps = NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
            if let activeWindow = apps.first(where:{$0.isActive}) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                let currPID = activeWindow.processIdentifier;
                if instanceIDs.contains(currPID) {
                    resetInstance(pid: currPID)
                } else {
                    instanceIDs.forEach { resetInstance(pid: $0) }
                }
            }
        }

        KeyboardShortcuts.onKeyDown(for: .planar) {
            print("planar")
            let apps = self.getAllApps()
            if let currentApp = apps.first(where:{$0.isActive}) {
                let args = Utils.processArguments(pid: currentApp.processIdentifier)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }

        getAllApps().forEach {
            print("\($0.localizedName ?? "nil") pid:\($0.processIdentifier) num: \(getInstanceNum(app: $0))")
            let num = getInstanceNum(app: $0)
            if num > 0 {
                print("name \($0.localizedName ?? "")")
            }
        }

        if instanceIDs.isEmpty {
            let byInstanceNum = instanceNums.swapKeyValues()
            instanceIDs = Array((1..<byInstanceNum.count).map({ byInstanceNum[$0] ?? 0 }))
            states = instanceIDs.map { pid in
                let data = InstanceInfo(pid: pid)
                if let args = Utils.processArguments(pid: pid) {
                    if let nativesArg = args.first(where: {$0.starts(with: "-Djava.library.path=")}) {
                        let arg = nativesArg.dropLast("/natives".count)
                                .dropFirst("-Djava.library.path=".count)
                        data.logPath = "\(arg)/.minecraft/logs/latest.log"
                    }
                }
                return data
            }
            print(instanceIDs)
            print(states)
        }
        updateStates()
    }

    /// kills all minecraft instances
    func killAll() {
        let task = Process()
        let killProcess = "killall prismlauncher;" + instanceIDs
                .map { "kill -9 \($0)" }
                .joined(separator: ";")
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", killProcess]
        task.launch()
        task.waitUntilExit()
    }

    func getAllApps() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
    }

    func getInstanceNum(app: NSRunningApplication) -> Int {
        let pid = app.processIdentifier
        if let num = instanceNums[pid] {
            return num
        } else {
            // get instance num from Command Line Arguments
            if app.localizedName == "java" {
                if let args = Utils.processArguments(pid: pid) {
                    if let nativesArg = args.first(where: {$0.starts(with: "-Djava.library.path=")}) {
                        let numTwo = nativesArg.dropLast("/natives".count).suffix(2)
                        let numChar = numTwo.suffix(1);
                        if let num = Int(numTwo) ?? Int(numChar) {
                            instanceNums[pid] = num
                            return num
                        }
                    }
                }
            }
            instanceNums[pid] = 0
            return 0
        }
    }

    func planar(app: NSRunningApplication) {
        if getInstanceNum(app: app) > 0 {

        }
    }

    func resetInstance(pid: pid_t) {
        sendReset(pid: pid)
        if let instNum = instanceNums[pid] {
            states[instNum - 1].state = .GENNING
        }
        playResetSound()
    }

    func playResetSound() {
        SoundManager.shared.playSound(sound: "reset")
    }

    func updateStates() {
        let instCount = instanceIDs.count
        for i in 0..<instCount {
            let data = states[i]

            if data.onNextF3 {
                data.onNextF3 = false
                sendF3Esc(pid: data.pid)
            }

            if data.state == InstanceState.GENNING || data.state == InstanceState.PREVIEW {
                let path = URL(fileURLWithPath: data.logPath)
                do {
                    let file = try FileHandle(forReadingFrom: path)
                    try file.seek(toOffset: data.logRead)
                    let rawData = String(data: try file.readToEnd() ?? Data(), encoding: .utf8)
                    data.logRead = try file.offset()
                    if data.state == InstanceState.GENNING {
                        if rawData?.contains("Starting Preview at") ?? false {
                            data.state = InstanceState.PREVIEW
                            data.onNextF3 = true
                        }
                    } else if rawData?.contains("joined the game") ?? false {
                        data.state = InstanceState.RUNNING
                        data.onNextF3 = true
                    }
                } catch {
                    print(error)
                }
            }

        }
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: DispatchTimeInterval.milliseconds(50))) {
            //print(self.states.map {"\($0.state) \($0.logRead)"})
            self.updateStates()
        }
    }


    func sendReset(pid: pid_t) {
        // send F6
        sendKey(key: 0x61, pid: pid)
    }

    func sendF3Esc(pid: pid_t) {
        // send F3 + ESC
        sendKeyCombo(keys: 0x63, 0x35, pid: pid)
        print("\(pid) << f3 esc")
    }

    func sendEscape(pid: pid_t) {
        sendKey(key: 0x35, pid: pid)
    }

    func sendKey(key: CGKeyCode, pid: pid_t) {
        print("Sending key \(key) to \(pid)")
        let src = CGEventSource(stateID: .hidSystemState)
        let kspd = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)
        let kspu = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)

        kspd?.postToPid( pid )
        kspu?.postToPid( pid )
    }

    func sendKeyCombo(keys: CGKeyCode..., pid: pid_t) {
        let src = CGEventSource(stateID: .hidSystemState)
        for key in keys {
            CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)?.postToPid(pid)
        }
        for key in keys.reversed() {
            CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)?.postToPid(pid)
        }
    }
}
