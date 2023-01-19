//
//  ShortcutManager.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI
import KeyboardShortcuts
import ScreenCaptureKit

final class ShortcutManager: ObservableObject {
    @Published var instanceNums = [pid_t:Int]()
    @Published var byInstanceNum = [Int:pid_t]()
    @Published var instanceIDs = [pid_t]()
    
    static let shared = ShortcutManager()
    
    init() {
        KeyboardShortcuts.onKeyUp(for: .reset) { [self] in
            print("reset")
            let apps = NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
            if let activeWindow = apps.first(where:{$0.isActive}) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                let currPID = activeWindow.processIdentifier;
                if instanceIDs.contains(currPID) {
                    sendKeys(pid: currPID)
                } else {
                    instanceIDs.forEach { sendKeys(pid: $0) }
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

        if byInstanceNum.isEmpty {
            byInstanceNum = instanceNums.swapKeyValues()
            instanceIDs = Array((1..<byInstanceNum.count).map({ byInstanceNum[$0] ?? 0 }))
        }
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
    
    func sendKeys(pid: pid_t) {
        sendReset(pid: pid)
    }

    func sendReset(pid: pid_t) {
        sendKey(key: 0x61, pid: pid)
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
}
