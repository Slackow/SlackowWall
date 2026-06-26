//
//  CrosshairManager.swift
//  SlackowWall
//
//  Floats a click-through crosshair window centered on the Minecraft window
//  during eye-measure (Tall) mode. Mirrors ResizeBackgroundManager, but the
//  window is centered on the game and ordered ABOVE it.
//

import AppKit
import SwiftUI

final class CrosshairManager: ObservableObject {
    static let shared = CrosshairManager()

    @Published private(set) var image: NSImage?
    @Published private(set) var isVisible = false

    private var window: NSPanel?
    private var targetPID: pid_t?
    private var targetWindowID: CGWindowID?

    private init() {}

    func showAutomatically(over instance: TrackedInstance) {
        let pid = instance.pid
        let windowID = instance.windowID
        DispatchQueue.main.async {
            guard Settings[\.utility].eyeCrosshairEnabled else { return }
            self.show(pid: pid, windowID: windowID)
        }
    }

    func hide() {
        DispatchQueue.main.async { self.hideImmediately() }
    }

    func hideAutomatically() {
        DispatchQueue.main.async { self.hideImmediately() }
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

    /// Re-apply appearance (image, capture visibility) and re-center while visible.
    func refreshAppearance() {
        DispatchQueue.main.async {
            guard self.isVisible, let pid = self.targetPID, let window = self.window else { return }
            let settings = Settings[\.utility]
            self.image =
                settings.eyeCrosshairStyle == .customImage
                ? settings.eyeCrosshairImage.flatMap { NSImage(contentsOf: $0) } : nil
            window.sharingType = settings.eyeCrosshairHideFromCapture ? .none : .readOnly
            self.positionWindow(pid: pid)
        }
    }

    private func show(pid: pid_t, windowID: CGWindowID?) {
        let settings = Settings[\.utility]
        guard settings.eyeCrosshairEnabled else {
            hideImmediately()
            return
        }

        image =
            settings.eyeCrosshairStyle == .customImage
            ? settings.eyeCrosshairImage.flatMap { NSImage(contentsOf: $0) } : nil

        targetPID = pid
        targetWindowID = windowID

        let window = makeWindow()
        window.sharingType = settings.eyeCrosshairHideFromCapture ? .none : .readOnly

        guard positionWindow(pid: pid) else {
            hideImmediately()
            return
        }

        window.orderFrontRegardless()
        if let windowID {
            window.order(.above, relativeTo: Int(windowID))
        }
        isVisible = true
    }

    @discardableResult
    private func positionWindow(pid: pid_t) -> Bool {
        guard
            let position = WindowController.getWindowPosition(pid: pid),
            let mcSize = WindowController.getWindowSize(pid: pid),
            let primary = NSScreen.primary
        else {
            return false
        }

        let settings = Settings[\.utility]
        let size = CGFloat(settings.eyeCrosshairSize)
        let offsetX = CGFloat(settings.eyeCrosshairOffsetX)
        let offsetY = CGFloat(settings.eyeCrosshairOffsetY)

        // AX position is top-left origin (y grows downward); convert center to Cocoa
        // global coordinates (bottom-left origin) using the primary screen height.
        let centerAXX = position.x + mcSize.width / 2
        let centerAXY = position.y + mcSize.height / 2
        let centerX = centerAXX + offsetX
        let centerY = primary.frame.maxY - centerAXY - offsetY

        window?.setFrame(
            CGRect(x: centerX - size / 2, y: centerY - size / 2, width: size, height: size),
            display: true)
        return true
    }

    private func hideImmediately() {
        window?.orderOut(nil)
        image = nil
        isVisible = false
        targetPID = nil
        targetWindowID = nil
    }

    private func makeWindow() -> NSPanel {
        if let window {
            return window
        }

        let window = CrosshairWindow(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier(SWWindowID.crosshair.rawValue)
        window.contentView = NSHostingView(rootView: CrosshairOverlayView())
        window.backgroundColor = .clear
        window.isOpaque = false
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
        window.level = .floating

        self.window = window
        return window
    }
}

private final class CrosshairWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
