//
//  NSSplitViewItem+Ext.swift
//  SlackowWall
//
//  Created by Kihron on 4/25/25.
//

import AppKit

/// An extension to `NSSplitViewItem` that prevents the sidebar from collapsing in a `NavigationSplitView` when displayed in the `SettingsWindow`.
///
/// This extension swizzles the `canCollapse` property to override its behavior, ensuring that the sidebar remains visible in the settings window.
/// The check is performed using the `isSettingsWindow` property of `NSWindow`.
///
/// - Note: Swizzling is used to modify the default behavior of `NSSplitViewItem.canCollapse` dynamically.
@MainActor extension NSSplitViewItem {
    @objc fileprivate var canCollapseSwizzled: Bool {
        if let check = self.viewController.view.window?.isSettingsWindow, check {
            return false
        }
        return self.canCollapseSwizzled
    }

    static func swizzle() {
        let origSelector = #selector(getter: NSSplitViewItem.canCollapse)
        let swizzledSelector = #selector(getter: canCollapseSwizzled)
        let originalMethodSet = class_getInstanceMethod(self as AnyClass, origSelector)
        let swizzledMethodSet = class_getInstanceMethod(self as AnyClass, swizzledSelector)

        method_exchangeImplementations(originalMethodSet!, swizzledMethodSet!)
    }
}

extension NSWindow {
    var isSettingsWindow: Bool {
        self.identifier?.rawValue == SWWindowID.settings.rawValue
    }
}
