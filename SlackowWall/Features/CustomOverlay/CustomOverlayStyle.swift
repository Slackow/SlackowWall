//
//  CustomOverlayStyle.swift
//  SlackowWall
//
//  Shape options for the custom overlay (e.g. a center crosshair) shown over
//  the Minecraft window.
//

import SwiftUI

enum CustomOverlayStyle: String, SettingsOption {
    case cross = "Cross"
    case dot = "Dot"
    case circle = "Circle"
    case crossDot = "Cross + Dot"
    case customImage = "Custom Image"

    var id: Self { self }
    var label: String { rawValue }
}
