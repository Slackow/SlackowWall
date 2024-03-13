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
                    HStack {
                        Text("Reset (global)")
                        Spacer()
                        KeybindingView(keybinding: KeybindingManager.shared.$resetGKey)
                    }
                    HStack {
                        Text("Reset all")
                        Spacer()
                        KeybindingView(keybinding: KeybindingManager.shared.$resetAllKey)
                    }
                    HStack {
                        Text("Run and reset others")
                        Spacer()
                        KeybindingView(keybinding: KeybindingManager.shared.$resetOthersKey)
                    }
                    HStack {
                        Text("Reset hovered")
                        Spacer()
                        KeybindingView(keybinding: KeybindingManager.shared.$resetOneKey)
                    }
                    HStack {
                        Text("Run")
                        Spacer()
                        KeybindingView(keybinding: KeybindingManager.shared.$runKey)
                    }
                    Button(action: {
                        KeybindingManager.shared.resetGKey = .keypad0
                        KeybindingManager.shared.resetAllKey = .t
                        KeybindingManager.shared.resetOneKey = .e
                        KeybindingManager.shared.resetOthersKey = .f
                        KeybindingManager.shared.runKey = .r
                        KeybindingManager.shared.lockKey = .c
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
