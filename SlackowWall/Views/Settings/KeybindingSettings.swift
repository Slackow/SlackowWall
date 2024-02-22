//
//  KeybindingSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI
import KeyboardShortcuts

struct KeybindingSettings: View {
    var body: some View {
        SettingsCardView(title: "Global Keybinds") {
            Form {
                KeyboardShortcuts.Recorder("Reset:", name: .reset)
                // KeyboardShortcuts.Recorder("Widen Instance:", name: .planar)
                Button("Reset To Defaults") {
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    UserDefaults.standard.synchronize()
                }
            }
            .padding()
        }
        .padding(.vertical, 10)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
