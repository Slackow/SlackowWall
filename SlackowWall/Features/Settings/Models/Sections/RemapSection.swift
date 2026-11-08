//
//  RemapSection.swift
//  SlackowWall
//

import DefaultCodable
import SwiftUI

extension Preferences {
    @DefaultCodable
    struct RemapSection: Codable, Hashable {
        var enabled: Bool = false
        var onlyInMinecraft: Bool = true
        var blockCommandQInMinecraft: Bool = false
        var remaps: [KeyRemap] = []

        init() {}
    }
}

/// A one-to-one key remap: pressing `from` sends `to` instead.
struct KeyRemap: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var from: KeyCode? = nil
    var to: KeyCode? = nil
    var enabled: Bool = true

    var isValid: Bool {
        guard enabled, let from, let to, from != to else { return false }
        return !mixesModifierAndKey
    }

    /// Modifiers can only be remapped to other modifiers, and normal keys to normal keys.
    var mixesModifierAndKey: Bool {
        guard let from, let to else { return false }
        return ModifierKey.isRemappable(from) != ModifierKey.isRemappable(to)
    }
}
