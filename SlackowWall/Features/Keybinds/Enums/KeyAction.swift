//
//  KeyAction.swift
//  SlackowWall
//
//  Created by Kihron on 7/21/24.
//

import SwiftUI

enum KeyAction {
    case run
    case resetOne
    case resetOthers
    case resetGlobal
    case resetAll
    case lock
    case toggleSensitivityScaling

    static func from(event: NSEvent) -> KeyAction? {
        let profile = Settings[\.keybinds]
        if profile.runKey.matches(event: event) { return .run }
        if profile.resetOneKey.matches(event: event) { return .resetOne }
        if profile.resetOthersKey.matches(event: event) { return .resetOthers }
        if profile.resetAllKey.matches(event: event) { return .resetAll }
        if profile.lockKey.matches(event: event) { return .lock }
        if profile.resetGKey.matches(event: event) { return .resetGlobal }
        if profile.sensitivityScalingGKey.matches(event: event) { return .toggleSensitivityScaling }
        return nil
    }
}
