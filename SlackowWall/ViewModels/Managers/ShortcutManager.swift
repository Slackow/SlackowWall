//
//  ShortcutManager.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI
import ScreenCaptureKit
import AVFoundation

final class ShortcutManager: ObservableObject {
    @Published var instanceNums = [pid_t:Int]()
    @Published var instanceIDs = [pid_t]()
    @Published var states = [InstanceInfo]()
    
    static let shared = ShortcutManager()

    
    func globalReset() {
        let apps = NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
        if let activeWindow = apps.first(where:{$0.isActive}) {
            NSApplication.shared.activate(ignoringOtherApps: true)
            let currPID = activeWindow.processIdentifier
            if instanceIDs.contains(currPID) {
                resetInstance(pid: currPID)
            }
        }
    }
    
    
    init() {

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
                        data.statePath = "\(arg)/.minecraft/wpstateout.txt"
                    }
                }
                return data
            }
            print(instanceIDs)
            print(states)
        }
        // updateStates()
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
                        let numChar = numTwo.suffix(1)
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
        if let instNum = instanceNums[pid] {
            let info = states[instNum - 1]
            info.checkState = .GENNING
            sendReset(pid: pid)
            playResetSound()
        }
    }

    func playResetSound() {
        SoundManager.shared.playSound(sound: "reset")
    }

    func updateStates() {
        let instCount = instanceIDs.count
        for i in 0..<instCount {
            let stateData = states[i]
            var sentF3 = false
            if stateData.untilF3 > 0 {
                stateData.untilF3 -= 1
                if stateData.untilF3 == 0 {
                    sendF3Esc(pid: stateData.pid)
                    sentF3 = true
                }
            }
            if !sentF3 && stateData.updateState() {
                print(stateData.description)
                if stateData.state == TITLE {} // if title
                else if stateData.state == PREVIEWING { // if previewing
                    stateData.untilF3 = 4
                } else if (stateData.prevState == PREVIEWING || stateData.prevState == WAITING) && stateData.state == UNPAUSED { // if prev state was world previewing
                    stateData.untilF3 = 4
                    stateData.checkState = .ENSURING
                    continue
                } else if stateData.state == UNPAUSED { // disable checking if slipped
                    stateData.checkState = .NONE
                }
            }
            if !sentF3 && stateData.checkState == .ENSURING {
                print(stateData.description)
                let _ = stateData.updateState()
                if stateData.state != UNPAUSED { // if not paused
                    stateData.checkState = .NONE
                    stateData.untilF3 = 0
                } else if stateData.untilF3 <= 0 {
                    stateData.untilF3 = 25
                }
            }

        }
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: DispatchTimeInterval.milliseconds(30))) {
            //print(self.states.map {"\($0.state) \($0.logRead)"})
            self.updateStates()
        }
    }


    func sendReset(pid: pid_t) {
        // send F6
        sendKey(key: 0x61, pid: pid)
    }
    
    func sendF1(pid: pid_t) {
        sendKey(key: 0x7A, pid: pid)
    }
    
    func sendF11(pid: pid_t) {
        sendKey(key: 0x67, pid: pid)
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
