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
    
    @MainActor static func from(keyCode: UInt16) -> KeyAction? {
        let profile = Settings[\.keybinds]
        switch keyCode {
            case profile.runKey:
                return .run
            case profile.resetOneKey:
                return .resetOne
            case profile.resetOthersKey:
                return .resetOthers
            case profile.resetAllKey:
                return .resetAll
            case profile.lockKey:
                return .lock
            case profile.resetGKey:
                return .resetGlobal
            default:
                return nil
        }
    }
}
