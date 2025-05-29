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
                            title: "Reset",
                            description:
                                "You may need to change this in [OBS](https://obsproject.com) too.",
                            font: .body)

                        KeybindingView(keybinding: $settings.resetGKey, defaultValue: nil)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Switch to Gameplay Mode",
                            description: "Go back to your normal dimensions quickly.", font: .body)

                        KeybindingView(keybinding: $settings.baseGKey, defaultValue: nil)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Tall Mode",
                            description: "Toggle between two resolutions quickly.", font: .body)

                        KeybindingView(keybinding: $settings.tallGKey, defaultValue: nil)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Thin Mode",
                            description: "Toggle between another set of resolutions.", font: .body)

                        KeybindingView(keybinding: $settings.thinGKey, defaultValue: nil)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Wide Mode",
                            description: "Toggle between another set of resolutions.", font: .body)

                        KeybindingView(keybinding: $settings.planarGKey, defaultValue: nil)
                    }
                }
            }

            SettingsLabel(
                title: "In-App Bindings",
                description: "These keybinds work only within SlackowWall itself."
            )
            .padding(.top, 5)

            SettingsCardView {
                VStack {
                    HStack {
                        SettingsLabel(title: "Reset All", font: .body)

                        KeybindingView(keybinding: $settings.resetAllKey, defaultValue: .t)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(title: "Reset Hovered", font: .body)

                        KeybindingView(keybinding: $settings.resetOneKey, defaultValue: .e)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Run Hovered and Reset Others",
                            description:
                                "You may need to change this in [OBS](https://obsproject.com) too.",
                            font: .body)

                        KeybindingView(keybinding: $settings.resetOthersKey, defaultValue: .f)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Run Hovered",
                            description:
                                "You may need to change this in [OBS](https://obsproject.com) too.",
                            font: .body)

                        KeybindingView(keybinding: $settings.runKey, defaultValue: .r)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Lock Hovered",
                            description: "You can also shift click instances to lock/unlock them.",
                            font: .body)

                        KeybindingView(keybinding: $settings.lockKey, defaultValue: .c)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            SettingsCardView {
                SettingsButtonView(
                    title: "Restore Defaults", buttonText: "Reset",
                    action: ShortcutManager.shared.resetKeybinds)
            }
        }
    }
}

#Preview {
    KeybindingsSettings()
}
