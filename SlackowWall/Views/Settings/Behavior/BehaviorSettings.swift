//
//  BehaviorSettings.swift
//  SlackowWall
//
//  Created by Andrew on 4/28/24.
//

import SwiftUI

struct BehaviorSettings: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var shortcutManager = ShortcutManager.shared

    var body: some View {
        SettingsPageView(title: "Behavior") {
            SettingsCardView {
                SettingsPickerView(title: "Reset Mode", description: profileManager.profile.resetMode.description, descInteractable: false, width: 70, selection: $profileManager.profile.resetMode)
            }

            SettingsCardView {
                VStack {
                    SettingsToggleView(title: "Utility Mode", description: "Allows Non-Numbered instances to be captured by SlackowWall, and enables some miscellaneous features.", descInteractable: false, option: $profileManager.profile.utilityMode)
                        .animation(.easeInOut, value: profileManager.profile.utilityMode)
                        .onChange(of: profileManager.profile.utilityMode) { newValue in
                            Task {
                                // Notification will handle the alert state changes
                                await ScreenRecorder.shared.resetAndStartCapture()
                            }
                        }

                    Divider()

                    SettingsToggleView(title: "Press F1 on Join", description: "[This option may be illegal and could invalidate runs.](0)", descInteractable: false, option: $profileManager.profile.f1OnJoin)
                        .tint(profileManager.profile.f1OnJoin ? .red : .gray)
                        .animation(.easeInOut, value: profileManager.profile.f1OnJoin)

                    Divider()

                    SettingsToggleView(title: "Pause on Lost Focus", description: "Pauses the capture of the instances when SlackowWall is not the focused window.", option: $profileManager.profile.onlyOnFocus)

                    Divider()

                    SettingsToggleView(title: "Hide Windows", description: "Hide all other instances when you enter an instance for performance, highly recommended.", option: $profileManager.profile.shouldHideWindows)
                }
            }

            SettingsCardView {
                SettingsToggleView(title: "Use State Output", description: "Turn this on if you have the state output mod, it prevents an instance from reseting if it is still generating the world.", option: $profileManager.profile.checkStateOutput)
            }
        }
        .animation(.easeInOut, value: profileManager.profile.resetMode)
    }
}

#Preview {
    BehaviorSettings()
}
