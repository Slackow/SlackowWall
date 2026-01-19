//
//  KeybindingsSettings.swift
//  SlackowWall
//
//  Created by Andrew on 1/12/26.
//

import SwiftUI

struct WallKeybindingsSettings: View {
    @AppSettings(\.keybinds) private var settings

    var body: some View {
        SettingsPageView(title: "Wall Keybinds", shouldDisableFocus: false) {
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

                        KeybindingView(keybinding: \.resetGKey)
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

                        KeybindingView(keybinding: \.resetAllKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(title: "Reset Hovered", font: .body)

                        KeybindingView(keybinding: \.resetOneKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Run Hovered and Reset Others",
                            description:
                                "You may need to change this in [OBS](https://obsproject.com) too.",
                            font: .body)

                        KeybindingView(keybinding: \.resetOthersKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Run Hovered",
                            description:
                                "You may need to change this in [OBS](https://obsproject.com) too.",
                            font: .body)

                        KeybindingView(keybinding: \.runKey)
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Lock Hovered",
                            description: "You can also shift click instances to lock/unlock them.",
                            font: .body)

                        KeybindingView(keybinding: \.lockKey)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
