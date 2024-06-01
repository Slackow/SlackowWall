//
//  ShortcutManager.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI
import ScreenCaptureKit
import AVFoundation
import ApplicationServices

final class ShortcutManager: ObservableObject {
    @Published var instanceNums = [pid_t:Int]()
    @Published var instanceIDs = [pid_t]()
    @Published var states = [InstanceInfo]()
    
    static let shared = ShortcutManager()
    
    init() {
        fetchInstanceInfo()
        
        // updateStates()
    }
    
    func fetchInstanceInfo() {
        fetchInstanceNums()
        fetchInstanceIDs()
    }
    
    private func fetchInstanceNums() {
        instanceNums.removeAll()
        
        getAllApps().forEach {
            print("\($0.localizedName ?? "nil") pid:\($0.processIdentifier) num: \(getInstanceNum(app: $0))")
            let num = getInstanceNum(app: $0)
            if num > 0 {
                LogManager.shared.appendLog("Window Name: \($0.localizedName ?? ""), Instance Number: \(num)")
            }
        }
    }
    
    private func fetchInstanceIDs() {
        instanceIDs.removeAll()
        
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
        
        LogManager.shared.appendLog("Instance IDs:", instanceIDs)
        logStatePaths()
        print(states)
    }
    
    func openFirstConfig() {
        guard let firstStatePath = states.first?.statePath else { return }
        let path = URL(filePath: firstStatePath).deletingLastPathComponent().appendingPathComponent("config")
        NSWorkspace.shared.open(path)
    }
    
    private func closeSettingsWindow() {
        NSApplication.shared.windows.filter({ $0.title == "Settings"}).first?.close()
    }
    
    private func logStatePaths() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        states.forEach { info in
            let sanitizedPath = info.statePath.replacingOccurrences(of: homeDirectory, with: "~")
            LogManager.shared.appendLog(sanitizedPath, showInConsole: false)
        }
    }
    
    func handleGlobalKey(_ key: NSEvent) {
        switch key.keyCode {
            case ProfileManager.shared.profile.resetGKey: globalReset()
            case ProfileManager.shared.profile.planarGKey: resizePlanar()
            case ProfileManager.shared.profile.altGKey: resizeAlt()
            case _: return
        }
    }
    
    func globalReset() {
        let apps = NSWorkspace.shared.runningApplications.filter{ $0.activationPolicy == .regular }
        guard let activeWindow = apps.first(where:{$0.isActive}) else { return }
        
        let pid = activeWindow.processIdentifier
        guard instanceIDs.contains(pid) else { return }
        
        LogManager.shared.appendLog("Returning...")
        resetInstance(pid: pid)
        
        if ProfileManager.shared.profile.shouldHideWindows {
            unhideInstances()
        }
        
        closeSettingsWindow()
        NSApp.activate(ignoringOtherApps: true)
        resizeReset(pid: pid)
        LogManager.shared.appendLog("Returned to SlackowWall")
    }
    
    func resizePlanar() {
        let apps = NSWorkspace.shared.runningApplications.filter{ $0.activationPolicy == .regular }
        guard let activeWindow = apps.first(where:{$0.isActive}), instanceIDs.contains(activeWindow.processIdentifier) else { return }
        let w = convertToFloat(ProfileManager.shared.profile.wideWidth)
        let h = convertToFloat(ProfileManager.shared.profile.wideHeight)
        let x = ProfileManager.shared.profile.wideX.map(CGFloat.init)
        let y = ProfileManager.shared.profile.wideY.map(CGFloat.init)
        resize(pid: activeWindow.processIdentifier, x: x, y: y, width: w, height: h)
    }
    
    func resizeBase(pid: pid_t) {
        let w = convertToFloat(ProfileManager.shared.profile.baseWidth)
        let h = convertToFloat(ProfileManager.shared.profile.baseHeight)
        let x = ProfileManager.shared.profile.baseX.map(CGFloat.init)
        let y = ProfileManager.shared.profile.baseY.map(CGFloat.init)
        resize(pid: pid, x: x, y: y, width: w, height: h, force: true)
    }
    
    func resizeReset(pid: pid_t) {
        let w = convertToFloat(ProfileManager.shared.profile.resetWidth)
        let h = convertToFloat(ProfileManager.shared.profile.resetHeight)
        let x = ProfileManager.shared.profile.resetX.map(CGFloat.init)
        let y = ProfileManager.shared.profile.resetY.map(CGFloat.init)
        resize(pid: pid, x: x, y: y, width: w, height: h, force: true)
    }
    
    func resizeAlt() {
        let apps = NSWorkspace.shared.runningApplications.filter{ $0.activationPolicy == .regular }
        guard let activeWindow = apps.first(where:{$0.isActive}), instanceIDs.contains(activeWindow.processIdentifier) else { return }
        let w = convertToFloat(ProfileManager.shared.profile.altWidth)
        let h = convertToFloat(ProfileManager.shared.profile.altHeight)
        let x = ProfileManager.shared.profile.altX.map(CGFloat.init)
        let y = ProfileManager.shared.profile.altY.map(CGFloat.init)
        resize(pid: activeWindow.processIdentifier, x: x, y: y, width: w, height: h)
    }
    
    func convertToFloat(_ int: Int?) -> CGFloat {
        return CGFloat(int ?? 0)
    }
    
    func resize(pid: pid_t, x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat, height: CGFloat, force: Bool = false) {
        let pids = ShortcutManager.shared.instanceIDs
        if !(width > 0 && height > 0) || pids.isEmpty {
            return
        }
        
        LogManager.shared.appendLog("Resizing Instance: \(pid)")
        
        let appRef = AXUIElementCreateApplication(pid)
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value) == .success, let windows = value as? [AXUIElement] else { return }
        for window in windows {
            var titleValue: AnyObject?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
            guard let title = titleValue as? String, title != "Window" else { continue }
        
            var posValue: AnyObject?
            var sizeValue: AnyObject?
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posValue)
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
            guard let posValue = posValue, let sizeValue = sizeValue else { return }
            
            var pos = CGPoint.zero
            var size = CGSize.zero
            AXValueGetValue(posValue as! AXValue, AXValueType.cgPoint, &pos)
            AXValueGetValue(sizeValue as! AXValue, AXValueType.cgSize, &size)
            
            if !force && size.width == width && size.height == height {
                resizeBase(pid: pid)
                return
            }
            
            var newSize = CGSize(width: width, height: height)
               
            
            var newPosition = CGPoint(x: x ?? (pos.x - (newSize.width - size.width) * 0.5),
                                      y: y ?? (pos.y - (newSize.height - size.height) * 0.5))
            
            guard let positionRef = AXValueCreate(AXValueType.cgPoint, &newPosition),
                    let sizeRef = AXValueCreate(AXValueType.cgSize, &newSize) else { continue }
            
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionRef)
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeRef)
            LogManager.shared.appendLog("Finished Resizing Instance: \(pid), \(newSize)")
        }
        
    }
    
    func unhideInstances() {
        let pids = ShortcutManager.shared.instanceIDs
        for pid in pids {
            let app = AXUIElementCreateApplication(pid)
            var error: AXError = AXError.success
            error = AXUIElementSetAttributeValue(app, kAXHiddenAttribute as CFString, kCFBooleanFalse)
            if error != .success {
                print("Error setting visibility attribute for PID \(pid): \(error)")
            }
        }
    }
    
    func killReplayD(){
        let task = Process()
        let killProcess = "killall -9 replayd"
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", killProcess]
        task.launch()
        task.waitUntilExit()
    }
    
    func killAll() {
        let runningApps = getAllApps()
        var appsToTerminate: [NSRunningApplication] = []
        
        // Send terminate signal to the apps
        for app in runningApps where instanceIDs.contains(app.processIdentifier) {
            app.terminate()
            appsToTerminate.append(app)
            LogManager.shared.appendLog("Terminating Instance:", app.processIdentifier, showInConsole: false)
        }
        
        // Check if the apps have terminated
        let queue = DispatchQueue.global(qos: .background)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: 0.1)
        
        timer.setEventHandler {
            if appsToTerminate.allSatisfy({ $0.isTerminated }) {
                timer.cancel()
                DispatchQueue.main.async {
                    LogManager.shared.appendLog("Closed SlackowWall", showInConsole: false)
                    exit(0)
                }
            }
        }
        
        timer.resume()
    }
    
    func getAllApps() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications.filter{  $0.activationPolicy == .regular }
    }
    
    func getInstanceNum(app: NSRunningApplication) -> Int {
        let pid = app.processIdentifier
        if let num = instanceNums[pid] {
            return num
        } else {
            if isMinecraftInstance(app: app) {
                if let args = Utils.processArguments(pid: pid) {
                    if let nativesArg = args.first(where: { $0.starts(with: "-Djava.library.path=") }) {
                        let numTwo = nativesArg.dropLast("/natives".count).suffix(2)
                        let numChar = numTwo.suffix(1)
                        if let num = UInt(numTwo) ?? UInt(numChar) {
                            let num = Int(num)
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
    
    func isMinecraftInstance(app: NSRunningApplication) -> Bool {
        if let args = Utils.processArguments(pid: app.processIdentifier) {
            let minecraftArgs = ["net.minecraft.client.main.Main", "-Djava.library.path="]
            for arg in minecraftArgs {
                if args.contains(where: { $0.contains(arg) }) {
                    return true
                }
            }
        }
        return false
    }
    
    func resetInstance(pid: pid_t) {
        if let instNum = instanceNums[pid] {
            let info = states[instNum - 1]
            info.checkState = .GENNING
            sendReset(pid: pid)
            playResetSound()
            InstanceManager.shared.unlockInstance(idx: instNum - 1)
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
                if stateData.state == InstanceStates.title {} // if title
                else if stateData.state == InstanceStates.previewing { // if previewing
                    stateData.untilF3 = 4
                } else if (stateData.prevState == InstanceStates.previewing || stateData.prevState == InstanceStates.waiting) && stateData.state == InstanceStates.unpaused { // if prev state was world previewing
                    stateData.untilF3 = 4
                    stateData.checkState = .ENSURING
                    continue
                } else if stateData.state == InstanceStates.unpaused { // disable checking if slipped
                    stateData.checkState = .NONE
                }
            }
            
            if !sentF3 && stateData.checkState == .ENSURING {
                print(stateData.description)
                stateData.updateState()
                if stateData.state != InstanceStates.unpaused { // if not paused
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
        sendKey(key: .f6, pid: pid)
    }
    
    func sendF1(pid: pid_t) {
        sendKey(key: .f1, pid: pid)
    }
    
    func sendF11(pid: pid_t) {
        sendKey(key: .f11, pid: pid)
    }
    
    func sendF3Esc(pid: pid_t) {
        // send F3 + ESC
        sendKeyCombo(keys: 0x63, 0x35, pid: pid)
        print("\(pid) << f3 esc")
    }
    
    func sendEscape(pid: pid_t) {
        sendKey(key: .escape, pid: pid)
    }
    
    func sendKey(key: CGKeyCode, pid: pid_t) {
        LogManager.shared.appendLog("Sending key \(key) to \(pid)")
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
    
    func resetKeybinds() {
        ProfileManager.shared.profile.resetGKey = .u
        ProfileManager.shared.profile.resetAllKey = .t
        ProfileManager.shared.profile.resetOneKey = .e
        ProfileManager.shared.profile.resetOthersKey = .f
        ProfileManager.shared.profile.runKey = .r
        ProfileManager.shared.profile.lockKey = .c
    }
}
