//
//  KeybindingSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct KeybindingSettings: View {
    var body: some View {
        VStack(spacing: 12) {
            SettingsCardView {
                Form {
                    Button(action: {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                        UserDefaults.standard.synchronize()
                    }) {
                        Text("Reset To Defaults")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

#Preview {
    KeybindingSettings()
}
