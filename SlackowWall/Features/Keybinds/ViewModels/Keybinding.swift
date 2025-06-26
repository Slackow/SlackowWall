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
    
    var isBound: Bool {
        !values.isEmpty
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
        func append(_ modifier: NSEvent.ModifierFlags, _ keycode: KeyCode) {
            if event.modifierFlags.contains(modifier),
                KeyCode.modifierFlags(code: event.keyCode) != modifier {
                vals.append(keycode)
            }
        }
        append(.command, .command)
        append(.shift, .shift)
        append(.option, .option)
        append(.control, .control)
        self.init(values: vals)
    }

    func matches(event: NSEvent) -> Bool {
        guard isBound else { return false }
        var other = Keybinding(event: event)
        
        // Remove duplicates of the pressed key from the modifier list so
        // modifier-only shortcuts match correctly.
        if let first = other.primaryKey {
            other.values = [first] + other.values.dropFirst().filter { $0 != first }
        }

        // Add F3 as a modifier if it's currently held down
        if ModifierKeyState.f3Pressed && other.primaryKey != .f3 {
            other.values.append(.f3)
        }

        let settings = Settings[\.keybinds]

        func remove(_ key: KeyCode, ignore: Bool) {
            if ignore && other.primaryKey != key && primaryKey != key && !modifiers.contains(key) {
                other.values.removeAll { $0 == key }
            }
        }
        
        remove(.shift, ignore: settings.ignoreShift)
        remove(.control, ignore: settings.ignoreControl)
        remove(.option, ignore: settings.ignoreOption)
        remove(.command, ignore: settings.ignoreCommand)
        remove(.f3, ignore: settings.ignoreF3)
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
