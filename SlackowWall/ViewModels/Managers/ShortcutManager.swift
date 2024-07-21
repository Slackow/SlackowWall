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
    static let shared = ShortcutManager()
    
    init() {
        
    }
    
    func openFirstConfig() {
        guard let firstStatePath = TrackingManager.shared.trackedInstances.first?.info.statePath else { return }
        let path = URL(filePath: firstStatePath).deletingLastPathComponent().appendingPathComponent("config")
        NSWorkspace.shared.open(path)
    }
    
    private func closeSettingsWindow() {
        NSApplication.shared.windows.filter({ $0.title == "Settings"}).first?.close()
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
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        guard let activeWindow = apps.first(where: { $0.isActive }) else { return }
        
        let pid = activeWindow.processIdentifier
        guard let instance = TrackingManager.shared.trackedInstances.first(where: { $0.pid == pid }) else { return }
        
        LogManager.shared.appendLog("Returning...")
        InstanceManager.shared.resetInstance(instance: instance)
        
        if ProfileManager.shared.profile.shouldHideWindows {
            unhideInstances()
        }
        
        closeSettingsWindow()
        NSApp.activate(ignoringOtherApps: true)
        resizeReset(pid: instance.pid)
        LogManager.shared.appendLog("Returned to SlackowWall")
    }
    
    func resizePlanar() {
        let apps = NSWorkspace.shared.runningApplications.filter{ $0.activationPolicy == .regular }
        guard let activeWindow = apps.first(where:{$0.isActive}), TrackingManager.shared.getValues(\.pid).contains(activeWindow.processIdentifier) else { return }
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
        guard let activeWindow = apps.first(where:{$0.isActive}), TrackingManager.shared.getValues(\.pid).contains(activeWindow.processIdentifier) else { return }
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
        let pids = TrackingManager.shared.getValues(\.pid)
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
        let pids = TrackingManager.shared.getValues(\.pid)
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
    
    func playResetSound() {
        SoundManager.shared.playSound(sound: "reset")
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
