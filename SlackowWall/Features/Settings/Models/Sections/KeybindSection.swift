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
        var tallGKey: KeyCode? = nil
        var thinGKey: KeyCode? = nil
        var planarGKey: KeyCode? = nil
        var baseGKey: KeyCode? = nil
        var resetAllKey: KeyCode? = .t
        var resetOthersKey: KeyCode? = .f
        var runKey: KeyCode? = .r
        var resetOneKey: KeyCode? = .e
        var lockKey: KeyCode? = .c

        init() {}
    }
}
