//
//  ShortcutManager.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import AVFoundation
import ApplicationServices
import ScreenCaptureKit
import SwiftUI

class ShortcutManager: ObservableObject, Manager {
    static let shared = ShortcutManager()

    @Published var eyeProjectorOpen: Bool = false {
        didSet {
            if !eyeProjectorOpen {
                NSApplication.shared.windows.first(where: { $0.title == "Eye Projector" })?.close()
            }
        }
    }

    init() {

    }

    private func closeSettingsWindow() {
        NSApplication.shared.windows.first(where: { $0.title == "Settings" })?.close()
    }

    func handleGlobalKey(_ key: NSEvent) {
        let settings = Settings[\.keybinds]
        switch (key.type, key.keyCode) {
            case (.keyUp, settings.resetGKey): globalReset()
            case (.keyDown, settings.planarGKey): resizePlanar()
            case (.keyDown, settings.baseGKey): resizeBase()
            case (.keyDown, settings.tallGKey): resizeTall()
            case (.keyDown, settings.thinGKey): resizeThin()
            case _: return
        }
    }

    func globalReset() {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        guard let activeWindow = apps.first(where: { $0.isActive }) else { return }

        let pid = activeWindow.processIdentifier
        guard let instance = TrackingManager.shared.trackedInstances.first(where: { $0.pid == pid })
        else { return }

        switch Settings[\.behavior].resetMode {
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

        if Settings[\.behavior].shouldHideWindows {
            WindowController.unhideWindows(TrackingManager.shared.getValues(\.pid))
        }

        closeSettingsWindow()
        NSApp.activate(ignoringOtherApps: true)
        resizeReset(pid: instance.pid)
        LogManager.shared.appendLog("Returned to SlackowWall")
    }

    private func handleLockMode(for instance: TrackedInstance) {
        guard
            let nextInstance = TrackingManager.shared.trackedInstances.first(where: {
                $0.isLocked == true
            })
        else {
            returnToWall(from: instance)
            return
        }

        InstanceManager.shared.openInstance(instance: nextInstance)
        InstanceManager.shared.resetInstance(instance: instance)
        resizeReset(pid: instance.pid)
    }

    private func handleMultiMode(for instance: TrackedInstance) {
        let trackedInstances = TrackingManager.shared.trackedInstances
        let totalInstances = trackedInstances.count

        guard
            let currentInstanceIndex = trackedInstances.firstIndex(where: { $0.pid == instance.pid }
            )
        else {
            returnToWall(from: instance)
            return
        }

        let nextInstance = (1..<totalInstances).lazy
            .map { (currentInstanceIndex + $0) % totalInstances }
            .map { index -> TrackedInstance in
                let candidate = trackedInstances[index]
                candidate.info.updateState(force: true)
                return candidate
            }
            .first(where: { $0.isReady })

        guard let nextInstance else {
            returnToWall(from: instance)
            return
        }

        InstanceManager.shared.openInstance(instance: nextInstance)
        InstanceManager.shared.resetInstance(instance: instance)
        resizeReset(pid: instance.pid)
    }

    func activeInstancePID() -> pid_t? {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        return apps.first(where: \.isActive).map(\.processIdentifier).flatMap { pid in
            TrackingManager.shared.getValues(\.pid).first { $0 == pid }
        }
    }

    func resizePlanar() {
        guard let pid = activeInstancePID() else { return }
        let w = convertToFloat(Settings[\.mode].wideWidth)
        let h = convertToFloat(Settings[\.mode].wideHeight)
        let x = Settings[\.mode].wideX.map(CGFloat.init)
        let y = Settings[\.mode].wideY.map(CGFloat.init)
        resize(pid: pid, x: x, y: y, width: w, height: h)
    }

    func resizeBase(pid: pid_t? = nil) {
        guard let pid = pid ?? activeInstancePID() else { return }
        let w = convertToFloat(Settings[\.mode].baseWidth)
        let h = convertToFloat(Settings[\.mode].baseHeight)
        let x = Settings[\.mode].baseX.map(CGFloat.init)
        let y = Settings[\.mode].baseY.map(CGFloat.init)
        resize(pid: pid, x: x, y: y, width: w, height: h, force: true)
    }

    func resizeReset(pid: pid_t) {
        var w = convertToFloat(Settings[\.mode].resetWidth)
        var h = convertToFloat(Settings[\.mode].resetHeight)
        var x = Settings[\.mode].resetX.map(CGFloat.init)
        var y = Settings[\.mode].resetY.map(CGFloat.init)

        if !(w > 0 && h > 0) {
            w = convertToFloat(Settings[\.mode].baseWidth)
            h = convertToFloat(Settings[\.mode].baseHeight)
            x = Settings[\.mode].baseX.map(CGFloat.init)
            y = Settings[\.mode].baseY.map(CGFloat.init)
        }
        resize(pid: pid, x: x, y: y, width: w, height: h, force: true)
    }

    func resizeThin() {
        guard let pid = activeInstancePID() else { return }
        let w = convertToFloat(Settings[\.mode].thinWidth)
        let h = convertToFloat(Settings[\.mode].thinHeight)
        let x = Settings[\.mode].thinX.map(CGFloat.init)
        let y = Settings[\.mode].thinY.map(CGFloat.init)
        resize(pid: pid, x: x, y: y, width: w, height: h)
    }

    func resizeTall() {
        guard let pid = activeInstancePID() else { return }
        let w = convertToFloat(Settings[\.mode].tallWidth)
        let h = convertToFloat(Settings[\.mode].tallHeight)
        let x = Settings[\.mode].tallX.map(CGFloat.init)
        let y = Settings[\.mode].tallY.map(CGFloat.init)
        if resize(pid: pid, x: x, y: y, width: w, height: h) == true {
            if let instance = TrackingManager.shared.trackedInstances.first(where: { $0.pid == pid }
            ) {
                ScreenRecorder.shared.eyeProjectedInstance = instance
                Task {
                    await ScreenRecorder.shared.startEyeProjectorCapture(for: instance)
                    if Settings[\.utility].eyeProjectorShouldOpenWithTallMode {
                        eyeProjectorOpen = true
                    }
                    MouseSensitivityManager.shared.setSensitivityFactor(
                        factor: Settings[\.utility].tallSensitivityScale)
                }
            }
        }
    }

    @discardableResult func resize(
        pid: pid_t, x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat, height: CGFloat,
        force: Bool = false
    ) -> Bool? {
        let pids = TrackingManager.shared.getValues(\.pid)
        if !(width > 0 && height > 0) || pids.isEmpty {
            return nil
        }

        LogManager.shared.appendLog("Resizing Instance: \(pid)")

        if let currentSize = WindowController.getWindowSize(pid: pid),
            let currentPosition = WindowController.getWindowPosition(pid: pid)
        {
            // detect exiting tall mode
            if currentSize
                == CGSize(
                    width: convertToFloat(Settings[\.mode].tallWidth),
                    height: convertToFloat(Settings[\.mode].tallHeight))
            {
                Task {
                    await ScreenRecorder.shared.stopEyeProjectorCapture()
                    ScreenRecorder.shared.eyeProjectedInstance = nil
                }
                if Settings[\.utility].eyeProjectorShouldOpenWithTallMode {
                    eyeProjectorOpen = false
                }
                MouseSensitivityManager.shared.setSensitivityFactor(
                    factor: Settings[\.utility].sensitivityScale)
            }
            if !force && currentSize.width == width && currentSize.height == height {
                resizeBase(pid: pid)
                return false
            }

            let newSize = CGSize(width: width, height: height)
            let newPosition = CGPoint(
                x: x ?? (currentPosition.x - (newSize.width - currentSize.width) * 0.5),
                y: y ?? (currentPosition.y - (newSize.height - currentSize.height) * 0.5))
            if let instance = TrackingManager.shared.trackedInstances.first(where: {
                $0.pid == pid && $0.info.port > 3
            }) {
                WindowController.sendResizeCommand(
                    instance: instance, x: Int(newPosition.x), y: Int(newPosition.y),
                    width: Int(newSize.width), height: Int(newSize.height))
            } else {
                WindowController.modifyWindow(
                    pid: pid, x: newPosition.x, y: newPosition.y, width: newSize.width,
                    height: newSize.height)
            }
            LogManager.shared.appendLog("Finished Resizing Instance: \(pid), \(newSize)")
            return true
        }
        return nil
    }

    func resetKeybinds() {
        Settings[\.keybinds] = .init()
    }

    func killReplayD() {
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
