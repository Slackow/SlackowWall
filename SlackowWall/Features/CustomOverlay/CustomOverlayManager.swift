//
//  CustomOverlayManager.swift
//  SlackowWall
//
//  Floats a click-through custom overlay window centered on the Minecraft
//  window during eye-measure (Tall) mode. Mirrors ResizeBackgroundManager, but
//  the window is centered on the game and ordered ABOVE it.
//

import AppKit
import SwiftUI

/// The resize modes the overlay can be shown in, each gated by its own setting.
enum OverlayMode {
    case wide, thin, tall, tallNoSens

    /// Whether the overlay is configured to show in this mode.
    var isEnabledInSettings: Bool {
        let settings = Settings[\.utility]
        switch self {
            case .wide: return settings.customOverlayShowInWide
            case .thin: return settings.customOverlayShowInThin
            case .tall: return settings.customOverlayShowInTall
            case .tallNoSens: return settings.customOverlayShowInTallNoSens
        }
    }
}

final class CustomOverlayManager: ObservableObject {
    static let shared = CustomOverlayManager()

    @Published private(set) var image: NSImage?
    @Published private(set) var isVisible = false

    private var window: NSPanel?
    private var targetPID: pid_t?
    private var targetWindowID: CGWindowID?

    private init() {}

    /// Show or hide the overlay for the resize mode an instance just entered,
    /// based on the master toggle and that mode's per-mode setting. Passing a
    /// nil instance (or a transient mode like reset) hides it.
    func updateVisibility(for mode: OverlayMode, over instance: TrackedInstance?) {
        guard let instance else {
            hide()
            return
        }
        let pid = instance.pid
        let windowID = instance.windowID
        DispatchQueue.main.async {
            guard Settings[\.utility].customOverlayEnabled, mode.isEnabledInSettings else {
                self.hideImmediately()
                return
            }
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
                settings.customOverlayStyle == .customImage
                ? settings.customOverlayImage.flatMap { NSImage(contentsOf: $0) } : nil
            window.sharingType = settings.customOverlayHideFromCapture ? .none : .readOnly
            self.positionWindow(pid: pid)
        }
    }

    private func show(pid: pid_t, windowID: CGWindowID?) {
        let settings = Settings[\.utility]
        guard settings.customOverlayEnabled else {
            hideImmediately()
            return
        }

        image =
            settings.customOverlayStyle == .customImage
            ? settings.customOverlayImage.flatMap { NSImage(contentsOf: $0) } : nil

        targetPID = pid
        targetWindowID = windowID

        let window = makeWindow()
        window.sharingType = settings.customOverlayHideFromCapture ? .none : .readOnly

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
        let size = CGFloat(settings.customOverlaySize)

        // AX position is top-left origin (y grows downward); convert center to Cocoa
        // global coordinates (bottom-left origin) using the primary screen height.
        let centerAXX = position.x + mcSize.width / 2
        let centerAXY = position.y + mcSize.height / 2
        let centerX = centerAXX
        let centerY = primary.frame.maxY - centerAXY

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

        let window = CustomOverlayWindow(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier(SWWindowID.customOverlay.rawValue)
        window.contentView = NSHostingView(rootView: CustomOverlayView())
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

private final class CustomOverlayWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
