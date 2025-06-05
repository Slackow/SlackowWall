//
//  SCWindow+Ext.swift
//  SlackowWall
//
//  Created by Kihron on 3/14/24.
//

import ScreenCaptureKit
import SwiftUI

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
            case (.some(let application), .some(let title)):
                return "\(application.applicationName): \(title)"
            case (.none, .some(let title)):
                return title
            case (.some(let application), .none):
                return "\(application.applicationName): \(windowID)"
            default:
                return ""
        }
    }
}

extension SCDisplay {
    var displayName: String {
        "Display: \(width) x \(height)"
    }
}
