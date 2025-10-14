//
//  ProfilesSettings.swift
//  SlackowWall
//
//  Created by Kihron on 5/17/24.
//

import SwiftUI

struct ProfilesSettings: View {
    @ObservedObject private var settings = Settings.shared
    @AppSettings(\.profile) private var profile

    var body: some View {
        SettingsPageView(title: "Profiles") {
            SettingsCardView {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Current Profile")

                        Text(
                            "Profiles allow for switching between different sets of setting configurations."
                        )
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.trailing, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("", selection: $settings.currentProfile) {
                        ForEach(settings.availableProfiles, id: \.id) { profile in
                            Text(profile.name)
                                .tag(profile.id)
                        }
                    }
                    .frame(maxWidth: 120)
                    .labelsHidden()
                }
            }

            SettingsLabel(title: "Properties")
                .padding(.top, 5)

            SettingsCardView {
                HStack {
                    Text("Name")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField(
                        "", text: $profile.name,
                        onCommit: {
                            if profile.name.isEmpty {
                                DispatchQueue.main.async {
                                    profile.name = "Default"
                                }
                            }
                        }
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                }
            }

            SettingsCardView {
                Form {
                    VStack {
                        VStack(spacing: 2) {
                            Text("Automatic Switching")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(
                                .init(
                                    "Automatically switches to this profile if the current monitor matches these dimensions."
                                )
                            )
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.gray)
                        }

                        HStack(spacing: 24) {
                            HStack {
                                TextField(
                                    "W", value: $profile.expectedMWidth,
                                    format: .number.grouping(.never)
                                )
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)

                                TextField(
                                    "H", value: $profile.expectedMHeight,
                                    format: .number.grouping(.never)
                                )
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            }

                            Button(action: fillMonitorSize) {
                                Text("Use Monitor")
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            SettingsCardView {
                VStack {
                    SettingsButtonView(
                        title: "Restore Default Settings",
                        description:
                            "Restores all settings to their default values for this profile.",
                        buttonText: "Restore Profile"
                    ) {
                        let name = Settings[\.profile].name
                        let id = Settings[\.profile].id
                        var newPrefs = Preferences()
                        newPrefs.profile.name = name
                        newPrefs.profile.id = id
                        Settings[\.self] = newPrefs
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: settings.createProfile) {
                    Image(systemName: "plus")
                }
                .popoverLabel("Create new profile")
                .disabled(settings.availableProfiles.count >= 10)

                Button(action: settings.deleteCurrentProfile) {
                    Image(systemName: "trash")
                }
                .popoverLabel("Remove current profile")
                .disabled(settings.availableProfiles.count <= 1)
            }
        }
        .onChange(of: profile.id) { _, value in
            if profile.id != value {
                Task {
                    try settings.switchProfile(to: value)
                    TrackingManager.shared.trackedInstances.forEach({ $0.stream.clearCapture() })
                    await ScreenRecorder.shared.resetAndStartCapture(shouldAutoSwitch: false)
                    GridManager.shared.showInfo = false
                }
            } else if Settings.shared.profileCreatedOrDeleted {
                Task {
                    await ScreenRecorder.shared.resetAndStartCapture(shouldAutoSwitch: false)
                    GridManager.shared.showInfo = false
                    Settings.shared.profileCreatedOrDeleted = false
                }
            }
        }
        .onChange(of: settings.currentProfile) { _, value in
            LogManager.shared.appendLog("Switched Profiles via picker:", value)
        }
    }

    private func fillMonitorSize() {
        if let frame = NSScreen.primary?.frame {
            profile.expectedMWidth = Int(frame.width)
            profile.expectedMHeight = Int(frame.height)
        }
    }
}

#Preview {
    ProfilesSettings()
}
