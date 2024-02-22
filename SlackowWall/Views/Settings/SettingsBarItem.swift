//
//  SettingsBarItem.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

enum SettingsBarItem: CaseIterable, Identifiable, Hashable {
    case instances, keybindings
    
    var id: Self {
        return self
    }
    
    var color: Color {
        switch self {
        case .instances:
            return .black
        case .keybindings:
            return .yellow
        }
    }
    
    var label: String {
        switch self {
        case .instances:
            return "Instances"
        case .keybindings:
            return "Keybindings"
        }
    }
    
    var icon: String {
        switch self {
        case .instances:
            return "compass.drawing"
        case .keybindings:
            return "hammer.fill"
        }
    }
}
