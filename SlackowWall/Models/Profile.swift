//
//  Profile.swift
//  SlackowWall
//
//  Created by Andrew on 5/14/24.
//

import SwiftUI

struct Profile: Codable, Identifiable {
    
    var id: UUID = UUID()
    var name: String = "New Profile"
    var sections: Int = 2
    var alignment: Alignment = .vertical
    
    var shouldHideWindows: Bool = true
    var showInstanceNumbers: Bool = true
    var forceAspectRatio: Bool = true
    
    var moveXOffset: Int = 0
    var moveYOffset: Int = 0
    
    var setWidth: Int? = nil
    var setHeight: Int? = nil
    
    var f1OnJoin: Bool = false
    var fullscreen: Bool = false
    var onlyOnFocus: Bool = true
    var checkStateOutput: Bool = true
    
    var resetWidth: Int? = nil
    var resetHeight: Int? = nil
    var resetX: Int? = nil
    var resetY: Int? = nil
    
    var baseWidth: Int? = nil
    var baseHeight: Int? = nil
    var baseX: Int? = nil
    var baseY: Int? = nil
    
    var wideWidth: Int? = nil
    var wideHeight: Int? = nil
    var wideX: Int? = nil
    var wideY: Int? = nil
    
    var baseDefined: Bool {
        return baseWidth != 0 && baseHeight != 0
    }

}
