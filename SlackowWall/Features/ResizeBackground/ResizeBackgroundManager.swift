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

    private var window: NSPanel?

    private init() {}

    func show(behind instance: TrackedInstance) {
        let windowID = instance.windowID

        DispatchQueue.main.async {
            self.show(windowID: windowID)
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.hideImmediately()
        }
    }

    private func show(windowID: CGWindowID?) {
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

        self.image = image

        let backgroundWindow = makeWindow()
        if let screen = NSScreen.primary {
            backgroundWindow.setFrame(screen.frame, display: true)
        }

        backgroundWindow.orderFrontRegardless()
        backgroundWindow.order(.below, relativeTo: Int(windowID))
    }

    private func hideImmediately() {
        window?.orderOut(nil)
        image = nil
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
        // Keep the image below normal Minecraft windows even if relative ordering fails.
        window.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)

        self.window = window
        return window
    }
}

private final class ResizeBackgroundWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
