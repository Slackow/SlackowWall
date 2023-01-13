//
//  ShortcutManager.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI
import KeyboardShortcuts
import ScreenCaptureKit

public final class ShortcutManager: ObservableObject {
    
    @Published public var instanceNums = [pid_t:Int]()
    
    @Published public var byInstanceNum = [Int:pid_t]()
    
    public static let shared = ShortcutManager();
    
    init() {
        KeyboardShortcuts.onKeyUp(for: .reset) {
            print("reset")
            let apps = NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
            if apps.first(where:{$0.isActive}) != nil {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if self.byInstanceNum.isEmpty {
                    self.byInstanceNum = self.instanceNums.swapKeyValues()
                }
                if let firstInstance = self.byInstanceNum[1] {
                    self.sendKeys(pid: firstInstance)
                    //apps.first(where: {app in app.processIdentifier == firstInstance})
                
                } else {
                    print("didn't find instance")
                }
                
            }
        }
        KeyboardShortcuts.onKeyDown(for: .planar) {
            print("planar")
            let apps = NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
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
                print("")
            }
        }
    }
    
    func getAllApps() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
    }
    
    func getCurrentApp() -> NSRunningApplication? {
        return getAllApps().first { $0.isActive }
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
                        let numChar = nativesArg.dropLast("/natives".count).suffix(1)
                        if let num = Int(numChar) {
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
        pressKey(key: 0x61, pid: pid)
    }
    
    func pressKey(key: CGKeyCode, pid: pid_t) {
        print("Sending key \(key) to \(pid)")
        let src = CGEventSource(stateID: .hidSystemState)
        let kspd = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)
        let kspu = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)
        
        kspd?.postToPid( pid );
        kspu?.postToPid( pid );
    }
}
