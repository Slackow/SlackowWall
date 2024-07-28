//
//  WallMode.swift
//  SlackowWall
//
//  Created by Kihron on 7/28/24.
//

import SwiftUI

enum WallMode: String, SettingsOption {
    case wall = "Wall"
    case lock = "Lock"
    case multi = "Multi"
    
    var id: Self {
        return self
    }
    
    var label: String {
        return rawValue
    }
}
