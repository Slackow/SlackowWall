//
//  SettingsBarItem.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

enum SettingsBarItem: CaseIterable, Identifiable, Hashable {
    case instances, keybindings, updates
    
    var id: Self {
        return self
    }
    
    var color: Color {
        switch self {
            case .instances:
                .black
            case .keybindings:
                .blue
            case .updates:
                .gray
        }
    }
    
    var label: String {
        switch self {
            case .instances:
                "Instances"
            case .keybindings:
                "Keybindings"
            case .updates:
                "Updates"
        }
    }
    
    var icon: String {
        switch self {
            case .instances:
                "compass.drawing"
            case .keybindings:
                "hammer.fill"
            case .updates:
                "gear.badge"
        }
    }
}
