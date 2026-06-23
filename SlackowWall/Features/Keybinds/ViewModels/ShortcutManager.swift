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

    private var tallModeEntries: [pid_t: TallModeEntry] = [:]

    @Published var eyeProjectorOpen: Bool = false {
        didSet {
            if !eyeProjectorOpen {
                NSApp.getWindow(.eyeProjector)?.close()
            }
        }
    }

    @Published var pieProjectorOpen: Bool = false {
        didSet {
            if !pieProjectorOpen {
                NSApp.getWindow(.pieProjector)?.close()
            }
        }
    }

    init() {

    }

    private func closeSettingsWindow() {
        NSApp.getWindow(.settings)?.close()
    }

    func handleGlobalKey(_ key: NSEvent) {
        var type = key.type
        guard type != .keyDown || !key.isARepeat else { return }
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
        } else if type == .keyDown {
            if settings.planarGKey.matches(event: key) {
                resizeWide()
            } else if settings.baseGKey.matches(event: key) {
                resizeBase()
            } else if settings.tallGKey.matches(event: key) {
                resizeTall()
            } else if settings.thinGKey.matches(event: key) {
                resizeThin()
            } else if settings.tallNoSensGKey.matches(event: key) {
                resizeTall(changeSens: false)
            } else if settings.sensitivityScalingGKey.matches(event: key) {
                Settings[\.utility].sensitivityScaleEnabled.toggle()
            } else if settings.ninjabrainBotHideGKey.matches(event: key) {
                NinjabrainManager.changeVisibility()
            } else if settings.resizeBackgroundToggleGKey.matches(event: key) {
                toggleResizeBackground()
            }
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
        guard case (.some(let w), let h, let x, let y) = Settings[\.self].wideDimensions else {
            return
        }
        let result = resize(
            pid: pid, x: x, y: y, width: w, height: h, resizeBackgroundAction: .show)
        clearTallModeEntry(pid: pid, if: result)
    }

    func toggleResizeBackground() {
        if ResizeBackgroundManager.shared.isVisible {
            ResizeBackgroundManager.shared.hide()
            return
        }

        let activeInstance = activeInstancePID().flatMap { pid in
            TrackingManager.shared.trackedInstances.first { $0.pid == pid }
        }
        guard let instance = activeInstance ?? TrackingManager.shared.trackedInstances.first else {
            return
        }

        ResizeBackgroundManager.shared.show(behind: instance)
    }

    @discardableResult func resizeBase(pid: pid_t? = nil) -> ResizeResult {
        guard let pid = pid ?? activeInstancePID(),
            case (.some(let w), .some(let h), .some(let x), .some(let y)) = Settings[\.self]
                .baseDimensions
        else {
            ResizeBackgroundManager.shared.hideAutomatically()
            return ResizeResult(type: .noResize)
        }
        let result = resize(
            pid: pid, x: x, y: y, width: w, height: h, force: true,
            resizeBackgroundAction: .hide)
        clearTallModeEntry(pid: pid, if: result)
        return result
    }

    func resizeReset(pid: pid_t) {
        guard
            case (.some(let w), .some(let h), .some(let x), .some(let y)) = Settings[\.self]
                .resetDimensions
        else {
            ResizeBackgroundManager.shared.hideAutomatically()
            return
        }
        let result = resize(
            pid: pid, x: x, y: y, width: w, height: h, force: true,
            resizeBackgroundAction: .hide)
        clearTallModeEntry(pid: pid, if: result)
    }

    func resizeThin() {
        guard let pid = activeInstancePID(),
            case (let w, .some(let h), let x, let y) = Settings[\.self].thinDimensions,
            let instance = TrackingManager.shared.trackedInstances.first(where: { $0.pid == pid })
        else { return }
        let shouldClearTallModeEntry = tallModeEntries[pid] != nil
        let projectorTransitionID = ScreenRecorder.shared.beginEyeProjectorTransition()
        let result = resize(
            pid: pid, x: x, y: y, width: w, height: h, dontClosePie: true,
            resizeBackgroundAction: .show,
            projectorTransitionID: projectorTransitionID)
        if shouldClearTallModeEntry {
            clearTallModeEntry(pid: pid, if: result)
        }
        if result.type == .resizedToOriginal && Settings[\.utility].pieProjectorEnabled {
            Task(priority: .userInitiated) {
                _ = await result.task?.result
                let didStartProjector = await ScreenRecorder.shared.startEyeProjectorCapture(
                    for: instance,
                    mode: Settings[\.utility].pieProjectorECountVisible ? .pie_and_e : .pie,
                    size: (w, h),
                    transitionID: projectorTransitionID
                )
                if didStartProjector && Settings[\.utility].pieProjectorShouldOpenWithThinMode {
                    pieProjectorOpen = true
                }
            }
        } else {
            clearTallModeEntry(pid: pid, if: result)
        }
    }

    func resizeTall(changeSens: Bool = true) {
        guard let pid = activeInstancePID() else { return }

        if changeSens,
            tallModeEntries[pid] == .noModifiersFromThin,
            isTallMode(pid: pid)
        {
            resizeThin()
            return
        }

        let usesNoModifiersFromThin =
            changeSens && Settings[\.mode].tallKeyUsesNoModifiersFromThin && isThinMode(pid: pid)
        let shouldChangeSens = usesNoModifiersFromThin ? false : changeSens

        let (w, h, x, y) = Settings[\.self].tallDimensions(
            for: TrackingManager.shared.trackedInstances.first { $0.pid == pid })
        let projectorTransitionID = ScreenRecorder.shared.beginEyeProjectorTransition()
        let result = resize(
            pid: pid, x: x, y: y, width: w, height: h, dontClosePie: !shouldChangeSens,
            resizeBackgroundAction: .show,
            projectorTransitionID: projectorTransitionID)

        if result.type == .resizedToOriginal,
            let instance = TrackingManager.shared.trackedInstances.first(where: { $0.pid == pid })
        {
            tallModeEntries[pid] = usesNoModifiersFromThin ? .noModifiersFromThin : .standard

            if shouldChangeSens {
                CrosshairManager.shared.showAutomatically(over: instance)
            }

            Task(priority: .userInitiated) {
                _ = await result.task?.result
                if shouldChangeSens {
                    MouseSensitivityManager.shared.setSensitivityFactor(
                        factor: Settings[\.utility].sensitivityScale
                            / Settings[\.utility].tallSensitivityFactor,
                        if: Settings[\.utility].tallSensitivityFactorEnabled)
                }
                let didStartProjector = await ScreenRecorder.shared.startEyeProjectorCapture(
                    for: instance,
                    mode: shouldChangeSens
                        ? .eye : (Settings[\.utility].pieProjectorECountVisible ? .pie_and_e : .pie),
                    transitionID: projectorTransitionID
                )
                if didStartProjector
                    && (shouldChangeSens
                        ? Settings[\.utility].eyeProjectorShouldOpenWithTallMode
                        : Settings[\.utility].pieProjectorShouldOpenWithTallMode)
                {
                    if shouldChangeSens {
                        eyeProjectorOpen = true
                    } else {
                        pieProjectorOpen = true
                    }
                }
            }
        }
    }
    // True means resized to dimension, False means resized but not to your dimension, nil means did not resize.
    @discardableResult func resize(
        pid: pid_t, x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat, height: CGFloat,
        force: Bool = false, dontClosePie: Bool = false,
        resizeBackgroundAction: ResizeBackgroundAction = .unchanged,
        projectorTransitionID: Int? = nil
    ) -> ResizeResult {
        let pids = TrackingManager.shared.getValues(\.pid)
        let instance = TrackingManager.shared.trackedInstances.first(where: { $0.pid == pid })
        if !(width > 0 && height > 0) || pids.isEmpty || instance?.info.isToolScreen == true {
            return ResizeResult(type: .noResize)
        }

        if let currentSize = WindowController.getWindowSize(pid: pid),
            let currentPosition = WindowController.getWindowPosition(pid: pid)
        {
            // detect exiting tall mode
            let (w, h, _, _) = Settings[\.self].tallDimensions(
                for: TrackingManager.shared.trackedInstances.first { $0.pid == pid })
            var task: Task<Void, Never>? = nil
            if currentSize == CGSize(width: w, height: h) {
                task = Task(priority: .userInitiated) {
                    await ScreenRecorder.shared.stopEyeProjectorCapture(
                        transitionID: projectorTransitionID)
                }
                CrosshairManager.shared.hideAutomatically()
                if Settings[\.utility].eyeProjectorShouldOpenWithTallMode || dontClosePie {
                    eyeProjectorOpen = false
                }
                if !dontClosePie {
                    pieProjectorOpen = false
                }
                MouseSensitivityManager.shared.setSensitivityFactor(
                    factor: Settings[\.utility].sensitivityScale)
                // detect exiting thin
            } else if !dontClosePie,
                case (let w, .some(let h), _, _) = Settings[\.self].thinDimensions,
                currentSize == CGSize(width: w, height: h)
            {
                pieProjectorOpen = false
                task = Task(priority: .userInitiated) {
                    await ScreenRecorder.shared.stopEyeProjectorCapture(
                        transitionID: projectorTransitionID)
                }
            }
            if !force && currentSize.width == width && currentSize.height == height {
                let task = resizeBase(pid: pid).task
                return ResizeResult(type: .resizedToOther, task: task)
            }
            guard
                let instance = TrackingManager.shared.trackedInstances.first(where: {
                    $0.pid == pid
                })
            else {
                LogManager.shared.appendLog("Instance with pid: \(pid) not found")
                ResizeBackgroundManager.shared.hideIfTargetRemoved(pid: pid)
                CrosshairManager.shared.hideIfTargetRemoved(pid: pid)
                return ResizeResult(type: .noResize)
            }
            if !force && Settings[\.mode].blockResizeWhenInGUI && instance.hasMod(.stateOutput) {
                instance.info.updateState(force: true)
                LogManager.shared.appendLog("Instance state:", instance.info.state)

                if instance.info.state != .unpaused {
                    return ResizeResult(type: .noResize)
                }
            }
            LogManager.shared.appendLog("Resizing Instance: \(pid)")

            let newSize = CGSize(width: width, height: height)
            let newPosition = CGPoint(
                x: x ?? (currentPosition.x - (newSize.width - currentSize.width) * 0.5),
                y: y ?? (currentPosition.y - (newSize.height - currentSize.height) * 0.5))
            if instance.hasMod(.boundless) {
                WindowController.sendResizeCommand(
                    instance: instance, x: Int(newPosition.x), y: Int(newPosition.y),
                    width: Int(newSize.width), height: Int(newSize.height))
            } else {
                WindowController.modifyWindow(
                    pid: pid, x: newPosition.x, y: newPosition.y, width: newSize.width,
                    height: newSize.height)
            }
            switch resizeBackgroundAction {
                case .show:
                    ResizeBackgroundManager.shared.showAutomatically(behind: instance)
                case .hide:
                    ResizeBackgroundManager.shared.hideAutomatically()
                case .unchanged:
                    break
            }
            LogManager.shared.appendLog("Finished Resizing Instance: \(pid), \(newSize)")
            return ResizeResult(type: .resizedToOriginal, task: task)
        }
        return ResizeResult(type: .noResize)
    }

    enum ResizeBackgroundAction {
        case show, hide, unchanged
    }

    struct ResizeResult {
        enum ResizeResultType {
            case resizedToOriginal, resizedToOther, noResize
        }
        let type: ResizeResultType
        var task: Task<Void, Never>? = nil
    }

    private func clearTallModeEntry(pid: pid_t, if result: ResizeResult) {
        guard result.type == .resizedToOriginal || result.type == .resizedToOther else {
            return
        }

        tallModeEntries[pid] = nil
    }

    private func isThinMode(pid: pid_t) -> Bool {
        guard
            let currentSize = WindowController.getWindowSize(pid: pid),
            case (let width, .some(let height), _, _) = Settings[\.self].thinDimensions
        else {
            return false
        }

        return currentSize == CGSize(width: width ?? currentSize.width, height: height)
    }

    private func isTallMode(pid: pid_t) -> Bool {
        guard let currentSize = WindowController.getWindowSize(pid: pid) else {
            return false
        }

        let (width, height, _, _) = Settings[\.self].tallDimensions(
            for: TrackingManager.shared.trackedInstances.first { $0.pid == pid })
        return currentSize == CGSize(width: width, height: height)
    }

    private enum TallModeEntry {
        case standard
        case noModifiersFromThin
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
