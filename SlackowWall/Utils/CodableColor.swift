//
//  CodableColor.swift
//  SlackowWall
//
//  A simple Codable + Hashable color type for persisting RGB colors in settings.
//

import SwiftUI

struct CodableColor: Codable, Hashable {
    var r: Double
    var g: Double
    var b: Double

    var color: Color {
        Color(red: r, green: g, blue: b)
    }

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(from color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.white
        self.r = Double(nsColor.redComponent)
        self.g = Double(nsColor.greenComponent)
        self.b = Double(nsColor.blueComponent)
    }
}
