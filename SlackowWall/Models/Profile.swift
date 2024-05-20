//
//  Profile.swift
//  SlackowWall
//
//  Created by Kihron on 5/17/24.
//

import SwiftUI

struct Profile {
    //Profile
    @AppStorage("\(activeProfileStore).profileName") var profileName: String = "Main"
    @AppStorage("\(activeProfileStore).expectedMWidth") var expectedMWidth: Int? = nil
    @AppStorage("\(activeProfileStore).expectedMHeight") var expectedMHeight: Int? = nil
    
    // Main
    @AppStorage("\(activeProfileStore).sections") var sections: Int = 2
    @AppStorage("\(activeProfileStore).alignment") var alignment: Alignment = .horizontal
    
    @AppStorage("\(activeProfileStore).shouldHideWindows") var shouldHideWindows = true
    @AppStorage("\(activeProfileStore).showInstanceNumbers") var showInstanceNumbers = true
    @AppStorage("\(activeProfileStore).forceAspectRatio") var forceAspectRatio = false
    
    @AppStorage("\(activeProfileStore).moveXOffset") var moveXOffset: Int? = nil
    @AppStorage("\(activeProfileStore).moveYOffset") var moveYOffset: Int? = nil
    
    @AppStorage("\(activeProfileStore).setWidth") var setWidth: Int? = nil
    @AppStorage("\(activeProfileStore).setHeight") var setHeight: Int? = nil
    
    // Behavior
    @AppStorage("\(activeProfileStore).f1OnJoin") var f1OnJoin: Bool = false
    @AppStorage("\(activeProfileStore).fullscreen") var fullscreen: Bool = false
    @AppStorage("\(activeProfileStore).onlyOnFocus") var onlyOnFocus: Bool = true
    @AppStorage("\(activeProfileStore).checkStateOutput") var checkStateOutput: Bool = false
    
    @AppStorage("\(activeProfileStore).resetWidth") var resetWidth: Int? = nil
    @AppStorage("\(activeProfileStore).resetHeight") var resetHeight: Int? = nil
    @AppStorage("\(activeProfileStore).resetX") var resetX: Int? = nil
    @AppStorage("\(activeProfileStore).resetY") var resetY: Int? = nil
    
    @AppStorage("\(activeProfileStore).baseWidth") var baseWidth: Int? = nil
    @AppStorage("\(activeProfileStore).baseHeight") var baseHeight: Int? = nil
    @AppStorage("\(activeProfileStore).baseX") var baseX: Int? = nil
    @AppStorage("\(activeProfileStore).baseY") var baseY: Int? = nil
    
    @AppStorage("\(activeProfileStore).wideWidth") var wideWidth: Int? = nil
    @AppStorage("\(activeProfileStore).wideHeight") var wideHeight: Int? = nil
    @AppStorage("\(activeProfileStore).wideX") var wideX: Int? = nil
    @AppStorage("\(activeProfileStore).wideY") var wideY: Int? = nil
    
    // Keybinds
    @AppStorage("\(activeProfileStore).resetGKey") var resetGKey: KeyCode? = .u
    @AppStorage("\(activeProfileStore).planarGKey") var planarGKey: KeyCode? = nil
    @AppStorage("\(activeProfileStore).planar2GKey") var planar2GKey: KeyCode? = nil
    @AppStorage("\(activeProfileStore).resetAllKey") var resetAllKey: KeyCode? = .t
    @AppStorage("\(activeProfileStore).resetOthersKey") var resetOthersKey: KeyCode? = .f
    @AppStorage("\(activeProfileStore).runKey") var runKey: KeyCode? = .r
    @AppStorage("\(activeProfileStore).resetOneKey") var resetOneKey: KeyCode? = .e
    @AppStorage("\(activeProfileStore).lockKey") var lockKey: KeyCode? = .c
    
    static var activeProfileStore: String {
        let identifier = UserDefaults.standard.string(forKey: "activeProfile")
        return identifier ?? "main"
    }
    
    init() {
        
    }
}
