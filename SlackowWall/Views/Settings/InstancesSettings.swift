//
//  InstancesSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct InstancesSettings: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var shortcutManager = ShortcutManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsLabel(title: "Grid Layout", description: "Control the grid layout of the instance previews in the main window.")

                SettingsCardView {
                    VStack {
                        Group {
                            Picker("", selection: $profileManager.profile.alignment) {
                                ForEach(Alignment.allCases, id: \.self) { type in
                                    Text(type == .vertical ? "Columns" : "Rows").tag(type)
                                }
                            }

                            Picker("", selection: $profileManager.profile.sections) {
                                ForEach(1..<10) {
                                    Text("\($0)").tag($0)
                                }
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                SettingsCardView {
                    VStack {
                        SettingsToggleView(title: "Force Aspect Ratio (16:9)", description: "Forces the instances to use this aspect ratio which is useful when using stretched instances.", option: $profileManager.profile.forceAspectRatio)

                        Divider()
                            .padding(.bottom, 4)

                        SettingsToggleView(title: "Show Instance Numbers", option: $profileManager.profile.showInstanceNumbers)
                    }
                }

                SettingsLabel(title: "Control Panel", description: "If you need help setting up SlackowWall, you can read the [setup guide](https://github.com/Slackow/SlackowWall/blob/main/Info/guide.md).")
                    .padding(.top, 5)

                SettingsCardView {
                    VStack {
                        SettingsButtonView(title: "Stop All (\(shortcutManager.instanceIDs.count))", description: "Closes all currently tracked instances and SlackowWall itself.", action: instanceManager.stopAll) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .disabled(instanceManager.isStopping)
                        .contentTransition(.numericText())
                        .animation(.linear, value: shortcutManager.instanceIDs.count)

                        Divider()
                            .padding(.bottom, 4)

                        SettingsButtonView(title: "Copy Mods to All", description: "Copies all mods from the first instance to all other open instances. This operation will close all instances.", buttonText: "Sync", action: instanceManager.copyMods)
                            .disabled(shortcutManager.instanceIDs.count < 2)

                        Divider()

                        SettingsButtonView(title: "First Instance Config", description: "Opens the config folder of the first instance.", buttonText: "...", action: shortcutManager.openFirstConfig)
                            .disabled(shortcutManager.instanceIDs.isEmpty)
                    }
                }

                SettingsCardView {
                    HStack(alignment: .top) {
                        SettingsLabel(title: "OBS Script", description: "This is the associated OBS script that helps you record using SlackowWall and switch scenes automatically.", font: .body)

                        Button(action: OBSManager.shared.copyScriptToClipboard) {
                            Text("Copy Path")
                        }

                        Button(action: OBSManager.shared.openScriptLocation) {
                            Text("...")
                        }
                    }
                }

                SettingsCardView {
                    VStack {
                        SettingsLabel(title: "Adjust Instances", description: "Modify the position, and optionally the width and height, of currently tracked instances.", font: .body)

                        Form {
                            HStack {
                                Group {
                                    TextField("X", value: $profileManager.profile.moveXOffset, format: .number.grouping(.never))
                                        .textFieldStyle(.roundedBorder)

                                    TextField("Y", value: $profileManager.profile.moveYOffset, format: .number.grouping(.never))
                                        .textFieldStyle(.roundedBorder)

                                    TextField("W", value: $profileManager.profile.setWidth, format: .number.grouping(.never))
                                        .textFieldStyle(.roundedBorder)

                                    TextField("H", value: $profileManager.profile.setHeight, format: .number.grouping(.never))
                                        .textFieldStyle(.roundedBorder)
                                }
                                .frame(width: 80)

                                Button(action: { instanceManager.move(forward: true, direct: true) }) {
                                    Text("Adjust")
                                }
                                .disabled(instanceManager.moving || shortcutManager.instanceIDs.isEmpty)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .removeFocusOnTap()
    }
}

#Preview {
    InstancesSettings()
        .frame(width: 600, height: 500)
}
