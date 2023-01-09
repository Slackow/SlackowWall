//
//  SlackowWallApp.swift
//  SlackowWall
//
//  Created by Andrew on 8/1/22.
//

import SwiftUI
import KeyboardShortcuts


@main
struct SlackowWallApp: App {
    @StateObject
    private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsScreen()
        }
    }
}


@MainActor
final class AppState: ObservableObject {
    
    private var instanceNums = [pid_t:Int]()
    
    
    init() {
        KeyboardShortcuts.onKeyUp(for: .reset) {
            print("reset")
            let apps = NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
            if apps.first(where:{$0.isActive}) != nil {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let firstInstance = self.instanceNums.swapKeyValues()[1] {
                    self.sendKeys(pid: firstInstance)
                    apps.first(where: {app in app.processIdentifier == firstInstance})
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
        let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
            
        let kspd = CGEvent(keyboardEventSource: src, virtualKey: 0x61, keyDown: true)   // f6-down
        let kspu = CGEvent(keyboardEventSource: src, virtualKey: 0x61, keyDown: false)  // f6-up https://gist.github.com/eegrok/949034
        kspd?.postToPid( pid );
        kspu?.postToPid( pid );
    }
    
}

struct SettingsScreen: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Reset:", name: .reset)
            KeyboardShortcuts.Recorder("Widen Instance:", name: .planar)
            Button("Reset To Defaults") {
                UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                UserDefaults.standard.synchronize()
            }
        }
    }
}
