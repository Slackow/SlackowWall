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
        var type = key.type
        if type == .flagsChanged,
            let code = KeyCode.modifierFlags(code: key.keyCode)
        {
            type = key.modifierFlags.contains(code) ? .keyDown : .keyUp
        }
        if key.keyCode == .f3 {
            (type == .keyDown ? ModifierKeyState.registerF3Down : ModifierKeyState.registerF3Up)()
        }
        let settings = Settings[\.keybinds]
        if type == .keyUp && settings.resetGKey.matches(event: key) {
            globalReset()
        } else if type == .keyDown && settings.planarGKey.matches(event: key) {
            resizeWide()
        } else if type == .keyDown && settings.baseGKey.matches(event: key) {
            resizeBase()
        } else if type == .keyDown && settings.tallGKey.matches(event: key) {
            resizeTall()
        } else if type == .keyDown && settings.thinGKey.matches(event: key) {
            resizeThin()
        } else if type == .keyDown && settings.sensitivityScalingGKey.matches(event: key) {
            Settings[\.utility].sensitivityScaleEnabled.toggle()
        } else {
            return
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
                trackedInstances[index].info.updateState(force: true)
                return trackedInstances[index]
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

    func resizeWide() {
        guard let pid = activeInstancePID() else { return }
        guard case let (.some(w), h, x, y) = Settings.shared.preferences.wideDimensions else {
            return
        }
        resize(pid: pid, x: x, y: y, width: w, height: h)
    }

    func resizeBase(pid: pid_t? = nil) {
        guard let pid = pid ?? activeInstancePID() else { return }
        guard
            case let (.some(w), .some(h), .some(x), .some(y)) = Settings.shared.preferences
                .baseDimensions
        else { return }
        resize(pid: pid, x: x, y: y, width: w, height: h, force: true)
    }

    func resizeReset(pid: pid_t) {
        guard
            case let (.some(w), .some(h), .some(x), .some(y)) = Settings.shared.preferences
                .resetDimensions
        else { return }
        resize(pid: pid, x: x, y: y, width: w, height: h, force: true)
    }

    func resizeThin() {
        guard let pid = activeInstancePID() else { return }
        guard case let (w, .some(h), x, y) = Settings.shared.preferences.thinDimensions else {
            return
        }
        resize(pid: pid, x: x, y: y, width: w, height: h)
    }

    func resizeTall() {
        guard let pid = activeInstancePID() else { return }
        let (w, h, x, y) = Settings.shared.preferences.tallDimensions
        if resize(pid: pid, x: x, y: y, width: w, height: h) == true {
            if let instance = TrackingManager.shared.trackedInstances.first(where: { $0.pid == pid }
            ) {
                ScreenRecorder.shared.eyeProjectedInstance = instance
                Task(priority: .userInitiated) {
                    MouseSensitivityManager.shared.setSensitivityFactor(
                        factor: Settings[\.utility].tallSensitivityScale)
                    await ScreenRecorder.shared.startEyeProjectorCapture(for: instance, mode: .tall)
                    if Settings[\.utility].eyeProjectorShouldOpenWithTallMode {
                        eyeProjectorOpen = true
                    }
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

        if let currentSize = WindowController.getWindowSize(pid: pid),
            let currentPosition = WindowController.getWindowPosition(pid: pid)
        {
            // detect exiting tall mode
            let (w, h, _, _) = Settings.shared.preferences.tallDimensions
            if currentSize == CGSize(width: w, height: h) {
                Task(priority: .userInitiated) {
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

            LogManager.shared.appendLog("Resizing Instance: \(pid)")

            let newSize = CGSize(width: width, height: height)
            let newPosition = CGPoint(
                x: x ?? (currentPosition.x - (newSize.width - currentSize.width) * 0.5),
                y: y ?? (currentPosition.y - (newSize.height - currentSize.height) * 0.5))
            if let instance = TrackingManager.shared.trackedInstances.first(where: {
                $0.pid == pid && $0.info.isBoundless
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
