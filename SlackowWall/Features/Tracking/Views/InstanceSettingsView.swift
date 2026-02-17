//
//  InstanceSettingsView.swift
//  SlackowWall
//
//  Created by Andrew on 2/15/26.
//

import SwiftUI

struct InstanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var instance: TrackedInstance

    private var checkBoateyeBinding: Binding<Bool> {
        Binding(
            get: { instance.shouldCheckBoateye },
            set: { instance.settings.checkBoateye = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instance Settings")
                .font(.title2)
                .fontWeight(.bold)

            Text("Instance \"\(instance.name)\"")
                .foregroundStyle(.secondary)

            SettingsCardView {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsToggleView(
                        title: "Validate Settings for BoatEye",
                        description:
                            "Check Minecraft and NinjabrainBot for the correct settings on instance detection.",
                        option: checkBoateyeBinding
                    )
                    .onChange(of: instance.shouldCheckBoateye) { _ in
                        instance.ninbotResults = nil
                        instance.minecraftResults = nil
                        instance.refreshBoatEyeStatus()
                    }
                    Divider()
                    SettingsToggleView(
                        title: "Auto Fix NinjabrainBot",
                        description: "Automatically apply NinjabrainBot fixes when issues are detected.",
                        option: $instance.settings.autoFixNinjabrainBot
                    )
                    Divider()
                    SettingsToggleView(
                        title: "Automatic World Clearing",
                        description:
                            "Automatically clear all but the last 40 worlds for this instance when detected. Runs about once a day, ignores maps and other files.",
                        infoBlurb: instance.hasMod(.ranked)
                            ? "MCSR Ranked has an option for this, you can configure it there instead." : nil,
                        option: $instance.settings.autoWorldClearing
                    )
                    //                    Divider()
                    //                    SettingsToggleView(
                    //                        title: "Auto Update Mods",
                    //                        description: "Automatically update detected legal mods on startup",
                    //                        option: $instance.settings.autoUpdateMods
                    //                    )
                    //                    Divider()
                    //                    SettingsToggleView(
                    //                        title: "Quit App On Instance Close",
                    //                        description: "Quit SlackowWall when this instance closes.",
                    //                        option: $instance.settings.quitAppOnInstanceClose
                    //                    )
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Close", role: .cancel) {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 360)
    }
}
