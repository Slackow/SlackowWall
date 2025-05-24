//
// Created by Kihron on 1/18/23.
//

import SwiftUI


@MainActor class InstanceManager: ObservableObject {
    @Published var hoveredInstance: TrackedInstance? = nil
    @Published var keyAction: KeyAction? = nil

    @Published var isStopping = false
    @Published var moving = false

    static let shared = InstanceManager()

    init() {

    }

    func openFirstConfig() {
        guard let firstInstance = TrackingManager.shared.trackedInstances.first(where: { $0.instanceNumber == 1 }) else { return }
        let statePath = firstInstance.info.statePath

        let path = URL(filePath: statePath).deletingLastPathComponent().appendingPathComponent("config")
        NSWorkspace.shared.open(path)
    }

    func copyMods() {
        guard let firstInstance = TrackingManager.shared.trackedInstances.first(where: { $0.instanceNumber == 1 }) else { return }
        let statePath = firstInstance.info.statePath

        let src = URL(filePath: statePath).deletingLastPathComponent().appendingPathComponent("mods")
        let fileManager = FileManager.default

        TrackingManager.shared.getValues(\.info).dropFirst().forEach {
            let dst = URL(filePath: $0.statePath).deletingLastPathComponent().appendingPathComponent("mods")

            print("Copying all from", src.path, "to", dst.path)

            do {
                if fileManager.fileExists(atPath: dst.path) {
                    try fileManager.removeItem(at: dst)
                }
                // Create the destination directory
                try fileManager.createDirectory(at: dst, withIntermediateDirectories: true, attributes: nil)

                // Get the list of items in the source directory
                let items = try fileManager.contentsOfDirectory(atPath: src.path)

                // Copy each item from the source to the destination
                for item in items {
                    let srcItem = src.appendingPathComponent(item)
                    let dstItem = dst.appendingPathComponent(item)
                    try fileManager.copyItem(at: srcItem, to: dstItem)
                }
            } catch { print(error.localizedDescription) }
        }

        TrackingManager.shared.killAll()
    }

    func handleKeyEvent(instance: TrackedInstance) {
        let pid = instance.pid

        if keyAction == .resetAll {
            resetAllUnlocked()
            keyAction = nil
            return
        }

        if hoveredInstance == nil {
            keyAction = nil
            return
        }

        if hoveredInstance == instance {
            switch keyAction {
                case .run:
                    openInstance(instance: instance)
                case .resetOne:
                    resetInstance(instance: instance)
                case .resetOthers:
                    enterAndResetUnlocked(instance: instance)
                case .resetAll:
                    KeyDispatcher.sendF3Esc(pid: pid)
                case .lock:
                    instance.toggleLock()
                case .resetGlobal:
                    ShortcutManager.shared.globalReset()
                case .none:
                    return
            }
            keyAction = nil
        }
    }

    private func switchToInstance(instance: TrackedInstance) {
        guard let windowID = instance.windowID else { return }
        let pid = instance.pid

        OBSManager.shared.writeWID(windowID: windowID)
        LogManager.shared.appendLog("Pressed: \(pid) #(\(instance.instanceNumber))")
        LogManager.shared.appendLog("Switching...")

        let actions = {
            if Settings[\.behavior].shouldHideWindows {
                let pids = TrackingManager.shared.getValues(\.pid).filter({$0 != pid})
                WindowController.hideWindows(pids)
            }

            KeyDispatcher.sendEscape(pid: pid)

            if Settings[\.behavior].f1OnJoin {
                KeyDispatcher.sendF1(pid: pid)
            }

            instance.info.checkState = .NONE
            LogManager.shared.appendLog("Switched to instance")
        }

        ShortcutManager.shared.resizeBase(pid: pid)
        NSApp.activate(ignoringOtherApps: true)
        WindowController.focusWindow(pid)
        actions()
    }

    func openInstance(instance: TrackedInstance) {
        instance.info.updateState(force: true)

        if !instance.isReady {
            instance.lock()
            return
        }

        switchToInstance(instance: instance)
        instance.unlock()
    }

    private func enterAndResetUnlocked(instance: TrackedInstance) {
        openInstance(instance: instance)

        for trackedInstance in TrackingManager.shared.trackedInstances {
            if trackedInstance != instance && canReset(instance: trackedInstance) {
                resetInstance(instance: trackedInstance)
            }
        }
    }

    private func canReset(instance: TrackedInstance) -> Bool {
        if instance.isLocked { return false }
        if !Settings[\.behavior].checkStateOutput { return true }
        let info = instance.info
        info.updateState(force: true)
        return info.state != InstanceStates.waiting && info.state != InstanceStates.generating
    }

    private func resetAllUnlocked() {
        LogManager.shared.appendLog("Reset all possible")
        for instance in TrackingManager.shared.trackedInstances {
            if canReset(instance: instance) {
                resetInstance(instance: instance)
            } else {
                LogManager.shared.appendLog("Did not reset: \(instance.pid), State: \(instance.info.state)")
            }
        }
    }

    func resetInstance(instance: TrackedInstance) {
        let info = instance.info
        info.checkState = .GENNING
        KeyDispatcher.sendReset(pid: instance.pid)
        instance.unlock()
    }

    func stopAll() {
        isStopping = true

        Task {
            await ScreenRecorder.shared.stop()
            TrackingManager.shared.killAll()
        }
    }

    func adjustInstances() async {
        await MainActor.run { self.moving = true }

        let profile = Settings[\.instance]
        let pids = TrackingManager.shared.getValues(\.pid)

        let x = CGFloat(profile.moveXOffset ?? 0)
        let y = CGFloat(profile.moveYOffset ?? 0)
        let width = CGFloat(profile.setWidth ?? 0)
        let height = CGFloat(profile.setHeight ?? 0)
        let setSize = width > 0 && height > 0

        if (x == 0 && y == 0 && !setSize) || pids.isEmpty {
            await MainActor.run { self.moving = false }
            return
        }

        if setSize {
            await MainActor.run {
                GridManager.shared.showInfo = false
            }

            await ScreenRecorder.shared.stop(removeStreams: true)
        }

        for pid in pids {
            WindowController.modifyWindow(pid: pid, x: x, y: y, width: width, height: height)
        }

        if setSize {
            await ScreenRecorder.shared.resetAndStartCapture()
        }

        await MainActor.run { self.moving = false }
    }
}
