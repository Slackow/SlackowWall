//
//  Keybinding.swift
//  SlackowWall
//
//  Created by Andrew on 6/19/25.
//

import Foundation

/// Wraps zero‐or‐more KeyCode values, but still encodes/decodes
/// a single KeyCode as just an integer.
struct Keybinding: Codable, Equatable, Hashable {
    var values: [KeyCode]

    var modifiers: Set<KeyCode> {
        Set(values[1...])
    }

    var primaryKey: KeyCode? {
        values.first
    }

    static let none = Keybinding()

    init(_ values: KeyCode...) {
        self.values = values
    }

    // Decode either one KeyCode or an array of them
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let single = try? container.decode(KeyCode.self) {
            self.values = [single]
        } else {
            self.values = try container.decode([KeyCode].self)
        }
    }

    // Encode single‐element arrays as a bare integer
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if values.count == 1 {
            try container.encode(values[0])
        } else {
            try container.encode(values)
        }
    }
}
