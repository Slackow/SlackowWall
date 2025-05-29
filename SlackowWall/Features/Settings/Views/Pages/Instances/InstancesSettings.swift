//
//  InstancesSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct InstancesSettings: View {
    @AppSettings(\.instance) private var settings

    @ObservedObject private var trackingManager = TrackingManager.shared
    @ObservedObject private var instanceManager = InstanceManager.shared

    var body: some View {
        SettingsPageView(title: "Instances") {
            SettingsLabel(
                title: "Grid Layout",
                description: "Control the grid layout of the instance previews in the main window.")

            SettingsCardView {
                VStack {
                    Group {
                        Picker("", selection: $settings.alignment) {
                            ForEach(Alignment.allCases, id: \.self) { type in
                                Text(type == .vertical ? "Columns" : "Rows").tag(type)
                            }
                        }

                        Picker("", selection: $settings.sections) {
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
                    SettingsToggleView(
                        title: "Force Aspect Ratio (16:9)",
                        description:
                            "Forces the instances to use this aspect ratio which is useful when using stretched instances.",
                        option: $settings.forceAspectRatio)

                    Divider()
                        .padding(.bottom, 4)

                    SettingsToggleView(
                        title: "Show Instance Numbers", option: $settings.showInstanceNumbers)
                }
            }

            SettingsLabel(
                title: "Control Panel",
                description:
                    "If you need help setting up SlackowWall, you can read the [setup guide](https://github.com/Slackow/SlackowWall/blob/main/Info/guide.md)."
            )
            .padding(.top, 5)

            SettingsCardView {
                VStack {
                    SettingsButtonView(
                        title: "Stop All (\(trackingManager.trackedInstances.count))",
                        description:
                            "Closes all currently tracked instances and SlackowWall itself.",
                        action: instanceManager.stopAll
                    ) {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                    }
                    .disabled(instanceManager.isStopping)
                    .contentTransition(.numericText())
                    .animation(.linear, value: trackingManager.trackedInstances.count)

                    Divider()
                        .padding(.bottom, 4)

                    SettingsButtonView(
                        title: "Copy Mods to All",
                        description:
                            "Copies all mods from the first instance to all other open instances. This operation will close all instances.",
                        buttonText: "Sync", action: instanceManager.copyMods
                    )
                    .disabled(trackingManager.trackedInstances.count < 2)

                    Divider()

                    SettingsButtonView(
                        title: "First Instance Config",
                        description: "Opens the config folder of the first instance.",
                        buttonText: "...", action: instanceManager.openFirstConfig
                    )
                    .disabled(trackingManager.trackedInstances.isEmpty)
                }
            }

            SettingsCardView {
                HStack(alignment: .top) {
                    SettingsLabel(
                        title: "OBS Script",
                        description:
                            "This is the associated OBS script that helps you record using SlackowWall and switch scenes automatically.",
                        font: .body)

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
                    SettingsLabel(
                        title: "Adjust Instances",
                        description:
                            "Modify the position, and optionally the width and height, of currently tracked instances.",
                        font: .body)

                    Form {
                        HStack {
                            Group {
                                TextField(
                                    "X", value: $settings.moveXOffset,
                                    format: .number.grouping(.never)
                                )
                                .textFieldStyle(.roundedBorder)

                                TextField(
                                    "Y", value: $settings.moveYOffset,
                                    format: .number.grouping(.never)
                                )
                                .textFieldStyle(.roundedBorder)

                                TextField(
                                    "W", value: $settings.setWidth, format: .number.grouping(.never)
                                )
                                .textFieldStyle(.roundedBorder)

                                TextField(
                                    "H", value: $settings.setHeight,
                                    format: .number.grouping(.never)
                                )
                                .textFieldStyle(.roundedBorder)
                            }
                            .frame(width: 80)

                            Button(action: { Task { await instanceManager.adjustInstances() } }) {
                                Text("Adjust")
                            }
                            .disabled(
                                instanceManager.moving || trackingManager.trackedInstances.isEmpty
                            )
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    InstancesSettings()
        .frame(width: 600, height: 500)
}
