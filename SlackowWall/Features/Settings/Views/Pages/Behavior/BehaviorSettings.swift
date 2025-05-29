//
//  BehaviorSettings.swift
//  SlackowWall
//
//  Created by Andrew on 4/28/24.
//

import SwiftUI

struct BehaviorSettings: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @AppSettings(\.behavior) private var settings

    var body: some View {
        SettingsPageView(title: "Behavior") {
            SettingsCardView {
                SettingsPickerView(
                    title: "Reset Mode", description: settings.resetMode.description,
                    descInteractable: false, width: 70, selection: $settings.resetMode)
            }

            SettingsCardView {
                VStack {
                    SettingsToggleView(
                        title: "Utility Mode",
                        description:
                            "Allows Non-Numbered instances to be captured by SlackowWall, and enables some miscellaneous features.",
                        descInteractable: false, option: $settings.utilityMode
                    )
                    .animation(.easeInOut, value: settings.utilityMode)
                    .onChange(of: settings.utilityMode) { newValue in
                        Task {
                            // Notification will handle the alert state changes
                            await ScreenRecorder.shared.resetAndStartCapture()
                        }
                    }

                    Divider()

                    SettingsToggleView(
                        title: "Press F1 on Join",
                        description: "[This option may be illegal and could invalidate runs.](0)",
                        descInteractable: false, option: $settings.f1OnJoin
                    )
                    .tint(settings.f1OnJoin ? .red : .gray)
                    .animation(.easeInOut, value: settings.f1OnJoin)

                    Divider()

                    SettingsToggleView(
                        title: "Pause on Lost Focus",
                        description:
                            "Pauses the capture of the instances when SlackowWall is not the focused window.",
                        option: $settings.onlyOnFocus)

                    Divider()

                    SettingsToggleView(
                        title: "Hide Windows",
                        description:
                            "Hide all other instances when you enter an instance for performance, highly recommended.",
                        option: $settings.shouldHideWindows)
                }
            }

            SettingsCardView {
                SettingsToggleView(
                    title: "Use State Output",
                    description:
                        "Turn this on if you have the state output mod, it prevents an instance from reseting if it is still generating the world.",
                    option: $settings.checkStateOutput)
            }
        }
        .animation(.easeInOut, value: settings.resetMode)
    }
}

#Preview {
    BehaviorSettings()
}
