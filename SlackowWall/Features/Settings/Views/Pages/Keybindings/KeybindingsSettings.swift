//
//  KeybindingsSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct KeybindingsSettings: View {
    @AppSettings(\.keybinds) private var settings

    var body: some View {
        SettingsPageView(title: "Keybinds", shouldDisableFocus: false) {
            SettingsLabel(
                title: "Global Bindings",
                description:
                    "These keybinds work system-wide and can be triggered within any application.")

            SettingsCardView {
                VStack {
                    HStack {
                        SettingsLabel(
                            title: "Switch to Gameplay Mode",
                            description: "Go back to your normal dimensions quickly.", font: .body)

                        KeybindingView(keybinding: \.baseGKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Tall Mode",
                            description: "Toggle between two resolutions quickly.", font: .body)

                        KeybindingView(keybinding: \.tallGKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Tall Mode (No Modifiers)",
                            description:
                                "Enter tall mode without activating projector/lowering sens",
                            font: .body)

                        KeybindingView(keybinding: \.tallNoSensGKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Thin Mode",
                            description: "Toggle between another set of resolutions.", font: .body)

                        KeybindingView(keybinding: \.thinGKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Wide Mode",
                            description: "Toggle between another set of resolutions.", font: .body)

                        KeybindingView(keybinding: \.planarGKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Sensitivity Scaling",
                            description: "Toggle Sensitivity Scaling on/off (global only).",
                            font: .body)

                        KeybindingView(keybinding: \.sensitivityScalingGKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Resize Background",
                            description: "Show or hide the selected resize background.",
                            font: .body)

                        KeybindingView(keybinding: \.resizeBackgroundToggleGKey)
                    }
                }
            }

            SettingsLabel(
                title: "Blocking Modifier Keys",
                description: "If enabled, these keys will block any keybind that doesn't use them."
            )
            .padding(.top, 5)

            SettingsCardView {
                VStack(alignment: .center, spacing: 10) {
                    HStack {
                        Toggle("Shift", isOn: $settings.blockingShift)
                        Toggle("Control", isOn: $settings.blockingControl)
                        Toggle("Option", isOn: $settings.blockingOption)
                        Toggle("Command", isOn: $settings.blockingCommand)
                        Toggle("F3", isOn: $settings.blockingF3)
                    }.frame(maxWidth: .infinity)
                }
            }

            SettingsCardView {
                SettingsButtonView(
                    title: "Restore Default Keybindings", buttonText: "Reset",
                    action: ShortcutManager.shared.resetKeybinds)
            }
        }
    }
}

#Preview {
    KeybindingsSettings()
}
