//
//  SlackowWallApp.swift
//  SlackowWall
//
//  Created by Andrew on 8/1/22.
//

import SwiftUI

@main
struct SlackowWallApp: App {
    @StateObject private var shortcutManager = ShortcutManager.shared;
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            SettingsView()
                .frame(width: 500, height: 300)
        }
    }
}
