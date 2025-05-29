//
//  Preferences.swift
//  SlackowWall
//
//  Created by Kihron on 5/3/25.
//

import DefaultCodable
import SwiftUI

@DefaultCodable
struct Preferences: Codable, Hashable {
    var profile: ProfileSection = .init()
    var instance: InstanceSection = .init()
    var behavior: BehaviorSection = .init()
    var mode: ModeSection = .init()
    var keybinds: KeybindSection = .init()
    var personalize: PersonalizeSection = .init()
    var utility: UtilitySection = .init()

    init() {}
}
