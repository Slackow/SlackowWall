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
        
        switch ProfileManager.shared.profile.resetMode {
            case .wall:
                returnToWall(from: instance)
            case .lock:
                handleLockMode(for: instance)
            case .multi:
                handleMultiMode(for: instance)
        }
    }
    
    private func returnToWall(from instance: TrackedInstance) {
        LogManager.shared.appendLog("Returning...")
        InstanceManager.shared.resetInstance(instance: instance)
        
        if ProfileManager.shared.profile.shouldHideWindows {
            WindowController.unhideWindows(TrackingManager.shared.getValues(\.pid))
        }
        
        closeSettingsWindow()
        NSApp.activate(ignoringOtherApps: true)
        resizeReset(pid: instance.pid)
        LogManager.shared.appendLog("Returned to SlackowWall")
    }
    
    private func handleLockMode(for instance: TrackedInstance) {
        guard let nextInstance = TrackingManager.shared.trackedInstances.first(where: { $0.isLocked == true }) else {
            returnToWall(from: instance)
            return
        }
        
        InstanceManager.shared.openInstance(instance: nextInstance, shouldWait: true)
        InstanceManager.shared.resetInstance(instance: instance)
        resizeReset(pid: instance.pid)
    }
    
    private func handleMultiMode(for instance: TrackedInstance) {
        let trackedInstances = TrackingManager.shared.trackedInstances
        let totalInstances = trackedInstances.count
        
        guard let currentInstanceIndex = trackedInstances.firstIndex(where: { $0.instanceNumber == instance.instanceNumber }) else {
            returnToWall(from: instance)
            return
        }
        
        let instanceCandidate = (1..<totalInstances).lazy
            .map { (currentInstanceIndex + $0) % totalInstances }
            .map { index -> TrackedInstance in
                let candidate = trackedInstances[index]
                candidate.info.updateState(force: true)
                return candidate
            }
            .first(where: { $0.isReady })
        
        guard let nextInstance = instanceCandidate else {
            returnToWall(from: instance)
            return
        }
        
        InstanceManager.shared.openInstance(instance: nextInstance, shouldWait: true)
        InstanceManager.shared.resetInstance(instance: instance)
        resizeReset(pid: instance.pid)
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
    
    func resize(pid: pid_t, x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat, height: CGFloat, force: Bool = false) {
        let pids = TrackingManager.shared.getValues(\.pid)
        if !(width > 0 && height > 0) || pids.isEmpty {
            return
        }
        
        LogManager.shared.appendLog("Resizing Instance: \(pid)")
        
        if let currentSize = WindowController.getWindowSize(pid: pid), let currentPosition = WindowController.getWindowPosition(pid: pid) {
            if !force && currentSize.width == width && currentSize.height == height {
                resizeBase(pid: pid)
                return
            }
            
            let newSize = CGSize(width: width, height: height)
            let newPosition = CGPoint(x: x ?? (currentPosition.x - (newSize.width - currentSize.width) * 0.5),
                                      y: y ?? (currentPosition.y - (newSize.height - currentSize.height) * 0.5))
            
            WindowController.modifyWindow(pid: pid, x: newPosition.x, y: newPosition.y, width: newSize.width, height: newSize.height)
            LogManager.shared.appendLog("Finished Resizing Instance: \(pid), \(newSize)")
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
    
    func killReplayD(){
        let task = Process()
        let killProcess = "killall -9 replayd"
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", killProcess]
        task.launch()
        task.waitUntilExit()
    }
    
    private func convertToFloat(_ int: Int?) -> CGFloat {
        return CGFloat(int ?? 0)
    }
}
