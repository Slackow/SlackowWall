//
//  CrosshairStyle.swift
//  SlackowWall
//
//  Style options for the center crosshair overlay shown during eye-measure mode.
//

import SwiftUI

enum CrosshairStyle: String, SettingsOption {
    case cross = "Cross"
    case dot = "Dot"
    case circle = "Circle"
    case crossDot = "Cross + Dot"
    case customImage = "Custom Image"

    var id: Self { self }
    var label: String { rawValue }
}
