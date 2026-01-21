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

    func setTitleBarVisibility(_ id: SWWindowID, isHidden: Bool) {
        guard let window = self.getWindow(id) else { return }
        //hide titlebar
        var frame = window.frame
        if isHidden == window.styleMask.contains(.titled) {
            frame.size.height -= isHidden ? 30 : -30
        }

        if isHidden {
            window.styleMask.remove(.titled)
        } else {
            window.styleMask.insert(.titled)
        }

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
    case settings = "settings-window"
    case slackowwall = "slackowwall-window"
}
