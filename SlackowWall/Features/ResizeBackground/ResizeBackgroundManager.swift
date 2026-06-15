//
//  ResizeBackgroundManager.swift
//  SlackowWall
//
//  Created by Codex on 6/1/26.
//

import AppKit
import SwiftUI

final class ResizeBackgroundManager: ObservableObject {
    static let shared = ResizeBackgroundManager()

    @Published private(set) var image: NSImage?
    @Published private(set) var isVisible = false

    private var window: NSPanel?
    private var targetPID: pid_t?

    private init() {}

    func show(behind instance: TrackedInstance) {
        let pid = instance.pid
        let windowID = instance.windowID

        DispatchQueue.main.async {
            self.show(pid: pid, windowID: windowID)
        }
    }

    func showAutomatically(behind instance: TrackedInstance) {
        let pid = instance.pid
        let windowID = instance.windowID

        DispatchQueue.main.async {
            guard Settings[\.mode].resizeBackgroundAutoAppearance else { return }
            self.show(pid: pid, windowID: windowID)
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.hideImmediately()
        }
    }

    func hideAutomatically() {
        DispatchQueue.main.async {
            guard Settings[\.mode].resizeBackgroundAutoAppearance else { return }
            self.hideImmediately()
        }
    }

    func hideIfTargetRemoved(pid: pid_t) {
        DispatchQueue.main.async {
            guard self.targetPID == pid else { return }
            self.hideImmediately()
        }
    }

    func hideIfTargetRemoved(_ removedPIDs: Set<pid_t>) {
        DispatchQueue.main.async {
            guard let targetPID = self.targetPID, removedPIDs.contains(targetPID) else { return }
            self.hideImmediately()
        }
    }

    private func show(pid: pid_t, windowID: CGWindowID?) {
        let settings = Settings[\.mode]
        guard settings.resizeBackgroundEnabled else {
            hideImmediately()
            return
        }
        guard let imageURL = settings.resizeBackgroundImage else {
            hideImmediately()
            return
        }
        guard let image = NSImage(contentsOf: imageURL) else {
            LogManager.shared.appendLog(
                "Failed to load resize background image:",
                imageURL.path(percentEncoded: false)
            )
            hideImmediately()
            return
        }
        guard let windowID else {
            LogManager.shared.appendLog("Could not show resize background: missing window ID")
            hideImmediately()
            return
        }

        let onScreenWindows = orderedOnScreenWindows()
        guard onScreenWindows.contains(where: { self.windowID(from: $0) == windowID }) else {
            LogManager.shared.appendLog("Could not show resize background: Minecraft window is gone")
            hideImmediately()
            return
        }

        targetPID = pid
        self.image = image

        let backgroundWindow = makeWindow()
        if let screen = NSScreen.primary {
            backgroundWindow.setFrame(screen.frame, display: true)
        }

        backgroundWindow.orderFrontRegardless()
        orderBackgroundWindow(backgroundWindow, belowExceptionsFor: windowID, in: onScreenWindows)
        isVisible = true
    }

    private func hideImmediately() {
        window?.orderOut(nil)
        image = nil
        isVisible = false
        targetPID = nil
    }

    private func makeWindow() -> NSPanel {
        if let window {
            return window
        }

        let window = ResizeBackgroundWindow(
            contentRect: NSScreen.primary?.frame ?? .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier(SWWindowID.resizeBackground.rawValue)
        window.contentView = NSHostingView(rootView: ResizeBackgroundView())
        window.backgroundColor = .black
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.canHide = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary,
        ]
        window.level = .normal

        self.window = window
        return window
    }

    private func orderBackgroundWindow(
        _ backgroundWindow: NSWindow,
        belowExceptionsFor targetWindowID: CGWindowID,
        in onScreenWindows: [[String: Any]]
    ) {
        let exceptionWindowIDs = exceptionWindowIDs(
            targetWindowID: targetWindowID,
            in: onScreenWindows)

        for windowInfo in onScreenWindows {
            guard
                let windowID = windowID(from: windowInfo),
                exceptionWindowIDs.contains(windowID)
            else {
                continue
            }

            backgroundWindow.order(.below, relativeTo: Int(windowID))
        }
    }

    private func exceptionWindowIDs(
        targetWindowID: CGWindowID,
        in onScreenWindows: [[String: Any]]
    ) -> Set<CGWindowID> {
        var windowIDs: Set<CGWindowID> = [targetWindowID]

        if let eyeProjectorWindow = NSApp.getWindow(.eyeProjector), eyeProjectorWindow.isVisible {
            windowIDs.insert(CGWindowID(eyeProjectorWindow.windowNumber))
        }

        if let pieProjectorWindow = NSApp.getWindow(.pieProjector), pieProjectorWindow.isVisible {
            windowIDs.insert(CGWindowID(pieProjectorWindow.windowNumber))
        }

        let ninjabrainPIDs = TrackingManager.shared.ninjabrainBotPIDs()
        for windowInfo in onScreenWindows where isNinjabrainBotWindow(windowInfo, pids: ninjabrainPIDs) {
            if let windowID = windowID(from: windowInfo) {
                windowIDs.insert(windowID)
            }
        }

        return windowIDs
    }

    private func orderedOnScreenWindows() -> [[String: Any]] {
        guard
            let windows = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID) as? [[String: Any]]
        else {
            return []
        }

        return windows
    }

    private func isNinjabrainBotWindow(_ windowInfo: [String: Any], pids: Set<pid_t>) -> Bool {
        if let pid = pid(from: windowInfo), pids.contains(pid) {
            return true
        }

        guard let ownerName = windowInfo[kCGWindowOwnerName as String] as? String else {
            return false
        }

        return ownerName.localizedCaseInsensitiveContains("Ninjabrain")
    }

    private func windowID(from windowInfo: [String: Any]) -> CGWindowID? {
        guard let value = windowInfo[kCGWindowNumber as String] else { return nil }

        if let number = value as? NSNumber {
            return CGWindowID(truncating: number)
        }

        return value as? CGWindowID
    }

    private func pid(from windowInfo: [String: Any]) -> pid_t? {
        guard let number = windowInfo[kCGWindowOwnerPID as String] as? NSNumber else {
            return nil
        }

        return pid_t(number.int32Value)
    }
}

private final class ResizeBackgroundWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
