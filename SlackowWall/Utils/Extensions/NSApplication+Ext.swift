//
//  NSApplication+Ext.swift
//  SlackowWall
//
//  Created by Andrew on 1/18/26.
//

import AppKit

extension NSApplication {
    func getWindow(_ id: SWWindowID) -> NSWindow? {
        self.windows.first { $0.identifier?.rawValue == id.rawValue }
    }

    func setWindowFloating(_ id: SWWindowID, isFloating: Bool) {
        self.getWindow(id)?.level = isFloating ? .floating : .normal
    }

    func setTitleBarVisibility(_ id: SWWindowID, isHidden: Bool, noReposition: Bool = false) {
        guard let window = self.getWindow(id) else { return }

        // Editing the titlebar in this manner seems to crash the entire app on 13.7.8-
        // If you can find a fix, I'm happy to include it
        if #unavailable(macOS 14.0) {
            return
        }
        //hide titlebar
        var frame = window.frame
        if !noReposition && isHidden == window.styleMask.contains(.titled) {
            frame.size.height -= isHidden ? 31 : -31
        }

        if isHidden {
            window.styleMask.remove(.titled)
        } else {
            window.styleMask.insert(.titled)
        }

        window.isMovableByWindowBackground = isHidden
        window.setFrame(frame, display: true)
        //        window.standardWindowButton(.closeButton)?.isHidden = isHidden
        //        window.standardWindowButton(.miniaturizeButton)?.isHidden = isHidden
        //        window.standardWindowButton(.zoomButton)?.isHidden = isHidden

        //hide title and bar
        //        window.titleVisibility = isHidden ? .hidden : .visible

    }
}

enum SWWindowID: String {
    case eyeProjector = "eye-projector-window"
    case pieProjector = "pie-projector-window"
    case resizeBackground = "resize-background-window"
    case crosshair = "crosshair-window"
    case settings = "settings-window"
    case slackowwall = "slackowwall-window"
}
