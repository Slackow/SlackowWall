//
//  SettingsBarItem.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

enum SettingsBarItem: CaseIterable, Identifiable, Hashable {
    case instances, keybindings, standardSettings, updates
    
    var id: Self {
        return self
    }
    
    var color: Color {
        switch self {
            case .instances:
                .init(red: 0.1, green: 0.1, blue: 0.1)
            case .keybindings:
                .blue
            case .standardSettings:
                .brown
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
            case .standardSettings:
                "Standard Settings"
            case .updates:
                "Updates"
        }
    }
    
    var icon: String {
        switch self {
            case .instances:
                "safari.fill"
            case .keybindings:
                "hammer.fill"
            case .standardSettings:
                "folder.fill.badge.gearshape"
            case .updates:
                "gear.badge"
        }
    }
}
