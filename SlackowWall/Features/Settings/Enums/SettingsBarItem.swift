//
//  SettingsBarItem.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

enum SettingsBarItem: CaseIterable, Identifiable, Hashable {
    case window_resizing, utilities, keybindings, profiles, updates, credits
    case instances, behavior, personalize, wall_keybindings

    var id: Self {
        return self
    }

    var isWallCategory: Bool {
        switch self {
            case .instances, .behavior, .personalize, .wall_keybindings:
                return true
            default:
                return false
        }
    }

    static let wallCases = Self.allCases.filter { $0.isWallCategory }
    static let generalCases = Self.allCases.filter { !$0.isWallCategory }

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
            case .keybindings, .wall_keybindings:
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
            case .wall_keybindings:
                "Wall Keybindings"
            case .personalize:
                "Personalize Wall"
            case .profiles:
                "Profiles"
            case .updates:
                "Updates"
            case .credits:
                "Credits & Help"
        }
    }

    var icon: ImageType {
        switch self {
            case .instances:
                .system("macwindow.on.rectangle")
            case .behavior:
                .system("hammer.fill")
            case .window_resizing:
                .asset("macwindow.and.pointer.arrow")
            case .utilities:
                .system("wrench.and.screwdriver.fill")
            case .keybindings, .wall_keybindings:
                .asset("arrowkeys.fill")
            case .personalize:
                .system("screwdriver.fill")
            case .profiles:
                .system("folder.fill")
            case .updates:
                .system("gear.badge")
            case .credits:
                .system("hands.sparkles.fill")
        }
    }

    var secondIcon: (ImageType, Color)? {
        switch self {
            case .credits:
                (.system("heart.fill"), .pink)
            default:
                nil
        }
    }
}
