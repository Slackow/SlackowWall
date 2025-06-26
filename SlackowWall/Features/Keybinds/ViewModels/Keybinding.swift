//
//  Keybinding.swift
//  SlackowWall
//
//  Created by Andrew on 6/19/25.
//

import AppKit
import Foundation

/// Wraps zero‐or‐more KeyCode values, but still encodes/decodes
/// a single KeyCode as just an integer.
struct Keybinding: Codable, Equatable, Hashable {
    var values: [KeyCode] = []

    var modifiers: Set<KeyCode> {
        Set(values.dropFirst())
    }

    var primaryKey: KeyCode? {
        values.first
    }

    static let none = Keybinding()

    init(_ values: KeyCode...) {
        self.values = values
    }

    init(values: [KeyCode]) {
        self.values = values
    }

    init(event: NSEvent) {
        var vals: [KeyCode] = [event.keyCode]
        if event.modifierFlags.contains(.command) { vals.append(.command) }
        if event.modifierFlags.contains(.shift) { vals.append(.shift) }
        if event.modifierFlags.contains(.option) { vals.append(.option) }
        if event.modifierFlags.contains(.control) { vals.append(.control) }
        self.init(values: vals)
    }

    func matches(event: NSEvent) -> Bool {
        var other = Keybinding(event: event)
        if !modifiers.contains(.shift) {
            other.values.removeAll { .shift == $0 }
        }
        if !modifiers.contains(.control) {
            other.values.removeAll { .control == $0 }
        }
        return other.primaryKey == primaryKey && other.modifiers == modifiers
    }

    var displayName: String {
        if values.isEmpty { return "None" }
        return values.map { KeyCode.toName(code: $0) }
            .reversed()
            .joined(separator: "+")
    }

    // Decode either one KeyCode or an array of them
    enum CodingKeys: String, CodingKey { case values }

    init(from decoder: Decoder) throws {
        if let singleContainer = try? decoder.singleValueContainer() {
            if let single = try? singleContainer.decode(KeyCode.self) {
                self.values = [single]
                return
            } else if let arr = try? singleContainer.decode([KeyCode].self) {
                self.values = arr
                return
            }
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.values = try container.decodeIfPresent([KeyCode].self, forKey: .values) ?? []
    }

    // Encode single‐element arrays as a bare integer
    func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        if values.count == 1 {
            try single.encode(values[0])
            return
        } else if !values.isEmpty {
            try single.encode(values)
            return
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(values, forKey: .values)
    }
}
