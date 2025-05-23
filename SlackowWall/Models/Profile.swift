//
//  Profile.swift
//  SlackowWall
//
//  Created by Kihron on 5/17/24.
//

import SwiftUI

struct Profile {
    // Profile
    @AppStorage(key("profileName")) var profileName: String = "Main"
    @AppStorage(key("expectedMWidth")) var expectedMWidth: Int? = nil
    @AppStorage(key("expectedMHeight")) var expectedMHeight: Int? = nil
    
    // Main
    @AppStorage(key("sections")) var sections: Int = 2
    @AppStorage(key("alignment")) var alignment: Alignment = .horizontal
    
    @AppStorage(key("shouldHideWindows")) var shouldHideWindows = true
    @AppStorage(key("showInstanceNumbers")) var showInstanceNumbers = true
    @AppStorage(key("forceAspectRatio")) var forceAspectRatio = false
    
    @AppStorage(key("moveXOffset")) var moveXOffset: Int? = nil
    @AppStorage(key("moveYOffset")) var moveYOffset: Int? = nil
    
    @AppStorage(key("setWidth")) var setWidth: Int? = nil
    @AppStorage(key("setHeight")) var setHeight: Int? = nil
    
    // Behavior
    @AppStorage(key("utilityMode")) var utilityMode: Bool = true {
        didSet {
            if oldValue != utilityMode {
                // Post notification when utility mode changes
                NotificationCenter.default.post(name: NSNotification.Name("UtilityModeChanged"), object: nil)
            }
        }
    }
    @AppStorage(key("f1OnJoin")) var f1OnJoin: Bool = false
    @AppStorage(key("fullscreen")) var fullscreen: Bool = false
    @AppStorage(key("onlyOnFocus")) var onlyOnFocus: Bool = true
    @AppStorage(key("checkStateOutput")) var checkStateOutput: Bool = false
    
    @AppStorage(key("resetMode")) var resetMode: ResetMode = .wall
    
    @AppStorage(key("resetWidth")) var resetWidth: Int? = nil
    @AppStorage(key("resetHeight")) var resetHeight: Int? = nil
    @AppStorage(key("resetX")) var resetX: Int? = nil
    @AppStorage(key("resetY")) var resetY: Int? = nil
    
    @AppStorage(key("baseWidth")) var baseWidth: Int? = nil
    @AppStorage(key("baseHeight")) var baseHeight: Int? = nil
    @AppStorage(key("baseX")) var baseX: Int? = nil
    @AppStorage(key("baseY")) var baseY: Int? = nil
    
    @AppStorage(key("wideWidth")) var wideWidth: Int? = nil
    @AppStorage(key("wideHeight")) var wideHeight: Int? = nil
    @AppStorage(key("wideX")) var wideX: Int? = nil
    @AppStorage(key("wideY")) var wideY: Int? = nil
    
    @AppStorage(key("thinWidth")) var thinWidth: Int? = nil
    @AppStorage(key("thinHeight")) var thinHeight: Int? = nil
    @AppStorage(key("thinX")) var thinX: Int? = nil
    @AppStorage(key("thinY")) var thinY: Int? = nil
    
    @AppStorage(key("tallWidth")) var tallWidth: Int? = nil
    @AppStorage(key("tallHeight")) var tallHeight: Int? = nil
    @AppStorage(key("tallX")) var tallX: Int? = nil
    @AppStorage(key("tallY")) var tallY: Int? = nil
    
    // Keybinds
    @AppStorage(key("resetGKey")) var resetGKey: KeyCode? = nil
    @AppStorage(key("tallGKey")) var tallGKey: KeyCode? = nil
    @AppStorage(key("thinGKey")) var thinGKey: KeyCode? = nil
    @AppStorage(key("planarGKey")) var planarGKey: KeyCode? = nil
    @AppStorage(key("baseGKey")) var baseGKey: KeyCode? = nil
    @AppStorage(key("resetAllKey")) var resetAllKey: KeyCode? = .t
    @AppStorage(key("resetOthersKey")) var resetOthersKey: KeyCode? = .f
    @AppStorage(key("runKey")) var runKey: KeyCode? = .r
    @AppStorage(key("resetOneKey")) var resetOneKey: KeyCode? = .e
    @AppStorage(key("lockKey")) var lockKey: KeyCode? = .c
    
    // Personalize
    @AppStorage(key("streamFPS")) var streamFPS: Double = 15
    
    @AppStorage(key("lockMode")) var lockMode: LockMode = .preset
    @AppStorage(key("selectedUserLock")) var selectedUserLock: UserLock? = nil
    @AppStorage(key("selectedLockPreset")) var selectedLockPreset: LockPreset = .apple
    @AppStorage(key("lockScale")) var lockScale: Double = 1
    @AppStorage(key("lockAnimation")) var lockAnimation: Bool = true
    
    private static var activeProfileStore: String {
        let identifier = UserDefaults.standard.string(forKey: "activeProfile")
        return identifier ?? "main"
    }
    
    private static func key(_ name: String) -> String {
        return "\(activeProfileStore).\(name)"
    }
    
    init() {
        
    }
}
