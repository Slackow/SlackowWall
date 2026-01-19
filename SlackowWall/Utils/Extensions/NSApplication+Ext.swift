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
}

enum SWWindowID: String {
    case eyeProjector = "eye-projector-window"
    case pieProjector = "pie-projector-window"
    case settings = "settings-window"
    case slackowwall = "slackowwall-window"
}
