//
//  KeybindSection.swift
//  SlackowWall
//
//  Created by Kihron on 5/5/25.
//

import DefaultCodable
import SwiftUI

extension Preferences {
    @DefaultCodable
    struct KeybindSection: Codable, Hashable {
        var resetGKey: Keybinding = .none
        var tallGKey: Keybinding = .none
        var thinGKey: Keybinding = .none
        var planarGKey: Keybinding = .none
        var baseGKey: Keybinding = .none
        var resetAllKey: Keybinding = .init(.t)
        var resetOthersKey: Keybinding = .init(.f)
        var runKey: Keybinding = .init(.r)
        var resetOneKey: Keybinding = .init(.e)
        var lockKey: Keybinding = .init(.c)

        var blockingShift: Bool = false
        var blockingControl: Bool = false
        var blockingOption: Bool = false
        var blockingCommand: Bool = true
        var blockingF3: Bool = true

        init() {}
    }
}
