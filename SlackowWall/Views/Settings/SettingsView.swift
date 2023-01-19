//
//  SettingsView.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        HStack {
            SettingsCardView(title: "Keybinds") {
                Form {
                    KeyboardShortcuts.Recorder("Reset:", name: .reset)
                    KeyboardShortcuts.Recorder("Widen Instance:", name: .planar)
                    Button("Reset To Defaults") {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                        UserDefaults.standard.synchronize()
                    }
                }
                .padding()
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
