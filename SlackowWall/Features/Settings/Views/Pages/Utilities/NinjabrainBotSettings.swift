//
//  NinjabrainBotSettings.swift
//  SlackowWall
//
//  Created by Andrew on 2/15/26.
//

import SwiftUI

struct NinjabrainBotSettings: View {

    @AppSettings(\.utility)
    var settings

    @State var showingOverlayFileImporter: Bool = false

    var body: some View {
        SettingsLabel(title: "NinjabrainBot", description: "NinjabrainBot settings")
        SettingsCardView {
            VStack {
                SettingsToggleView(
                    title: "Auto-Launch NinjabrainBot", description: "Launch Ninjabrain Bot on SlackowWall startup",
                    option: $settings.ninjabrainBotAutoLaunch)
                Divider()
                SettingsToggleView(
                    title: "Launch NinjabrainBot when detecting instance",
                    description:
                        "If an MCSR instance is detected, launch NinjabrainBot if its closed",
                    option: $settings.ninjabrainBotLaunchWhenDetectingInstance)
                Divider()
                HStack {
                    SettingsLabel(title: "NinjabrainBot Location", font: .body)
                    if settings.ninjabrainBotLocation != nil {
                        Button {
                            settings.ninjabrainBotLocation = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                    }
                    Button(
                        settings.ninjabrainBotLocation.flatMap(\.lastPathComponent)
                            ?? "Select Jar File"
                    ) {
                        showingOverlayFileImporter = true
                    }
                    .fileImporter(
                        isPresented: $showingOverlayFileImporter,
                        allowedContentTypes: [.archive], allowsMultipleSelection: false
                    ) { result in
                        switch result {
                            case .success(let urls):
                                settings.ninjabrainBotLocation = urls.first
                            case .failure(let error):
                                LogManager.shared.appendLog(
                                    "Failed to select ninjabrain",
                                    error.localizedDescription)
                        }
                    }

                }
            }
        }
    }
}

#Preview {
    NinjabrainBotSettings()
}
