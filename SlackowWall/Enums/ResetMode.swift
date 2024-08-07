//
//  ResetMode.swift
//  SlackowWall
//
//  Created by Kihron on 7/28/24.
//

import SwiftUI

enum ResetMode: String, SettingsOption {
    case wall = "Wall"
    case lock = "Lock"
    case multi = "Multi"
    
    var id: Self {
        return self
    }
    
    var label: String {
        return rawValue
    }
    
    var description: String {
        switch self {
            case .wall:
                """
                Returns to the wall after each run is reset.
                
                • Your [OBS](0) "Run Instance" hotkey should include: "\(getKeyName(ProfileManager.shared.profile.runKey))" and "\(getKeyName(ProfileManager.shared.profile.resetOthersKey))".
                • Your [OBS](0) "Switch to scene" hotkey should be: "\(getKeyName(ProfileManager.shared.profile.resetGKey))".
                """
            case .lock:
                """
                Immediately switches to the next locked instance if available.
                
                • Your [OBS](0) "Run Instance" hotkey should include: "\(getKeyName(ProfileManager.shared.profile.runKey))", "\(getKeyName(ProfileManager.shared.profile.resetOthersKey))", "\(getKeyName(ProfileManager.shared.profile.resetGKey))".
                • Your [OBS](0) "Switch to scene" hotkey should be: "\(getKeyName(ProfileManager.shared.profile.resetGKey))".
                """
            case .multi:
                """
                Bypasses the wall entirely and cycles between all tracked instances.
                
                • Your [OBS](0) "Run Instance" hotkey should include: "\(getKeyName(ProfileManager.shared.profile.runKey))", "\(getKeyName(ProfileManager.shared.profile.resetOthersKey))", "\(getKeyName(ProfileManager.shared.profile.resetGKey))".
                • Your [OBS](0) "Switch to scene" hotkey does not need to be set.
                """
        }
    }
    
    private func getKeyName(_ code: KeyCode?) -> String {
        return KeyCode.toName(code: code)
    }
}
