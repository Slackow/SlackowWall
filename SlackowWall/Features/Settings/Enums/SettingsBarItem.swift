//
//  SettingsBarItem.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

enum SettingsBarItem: CaseIterable, Identifiable, Hashable {
    case instances, behavior, window_resizing, utilities, keybindings, personalize, profiles,
        updates, credits

    var id: Self {
        return self
    }

    var color: Color {
        switch self {
            case .instances:
                .init(red: 0.1, green: 0.1, blue: 0.1)
            case .behavior:
                .indigo
            case .window_resizing:
                .orange
            case .utilities:
                .teal
            case .keybindings:
                .blue
            case .personalize:
                .red
            case .profiles:
                .init(red: 0, green: 0.7, blue: 0.4)
            case .updates:
                .gray
            case .credits:
                .brown
        }
    }

    var label: String {
        switch self {
            case .instances:
                "Instances"
            case .behavior:
                "Wall Behavior"
            case .window_resizing:
                "Window Resizing"
            case .utilities:
                "Utilities"
            case .keybindings:
                "Keybindings"
            case .personalize:
                "Personalize"
            case .profiles:
                "Profiles"
            case .updates:
                "Updates"
            case .credits:
                "Credits & Help"
        }
    }

    var icon: String {
        switch self {
            case .instances:
                "macwindow.on.rectangle"
            case .behavior:
                "hammer.fill"
            case .window_resizing:
                "macwindow.and.cursorarrow"
            case .utilities:
                "wrench.and.screwdriver.fill"
            case .keybindings:
                "arrowkeys.fill"
            case .personalize:
                "screwdriver.fill"
            case .profiles:
                "folder.fill"
            case .updates:
                "gear.badge"
            case .credits:
                "hands.and.sparkles.fill"
        }
    }
}
