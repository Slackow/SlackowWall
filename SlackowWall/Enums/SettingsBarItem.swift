//
//  SettingsBarItem.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

enum SettingsBarItem: CaseIterable, Identifiable, Hashable {
    case instances, behavior, keybindings, updates
    
    var id: Self {
        return self
    }
    
    var color: Color {
        switch self {
            case .instances:
                .init(red: 0.1, green: 0.1, blue: 0.1)
            case .keybindings:
                .blue
            case .behavior:
                .brown
            case .updates:
                .gray
        }
    }
    
    var label: String {
        switch self {
            case .instances:
                "Instances"
            case .behavior:
                "Behavior"
            case .keybindings:
                "Keybindings"
            case .updates:
                "Updates"
        }
    }
    
    var icon: String {
        switch self {
            case .instances:
                "safari.fill"
            case .behavior:
                "hammer.fill"
            case .keybindings:
                "arrowkeys.fill"
            case .updates:
                "gear.badge"
        }
    }
}
