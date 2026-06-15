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
        SettingsLabel(
            title: "NinjabrainBot",
            description: .init(
                "[NinjabrainBot](https://www.github.com/ninjabrain1/ninjabrain-bot) is the calculator used to calculate the stronghold location"
            ))
        SettingsCardView {
            VStack {
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
                    .if(settings.ninjabrainBotLocation != nil) {
                        $0.popoverLabel(settings.ninjabrainBotLocation?.path(percentEncoded: false) ?? "")
                    }
                }
                Divider()
                SettingsToggleView(
                    title: "Auto-Launch NinjabrainBot", description: "Launch Ninjabrain Bot on SlackowWall startup.",
                    option: $settings.ninjabrainBotAutoLaunch)
                Divider()
                SettingsToggleView(
                    title: "Launch NinjabrainBot when detecting instance",
                    description:
                        "If an MCSR instance is detected, launch NinjabrainBot if its closed.",
                    option: $settings.ninjabrainBotLaunchWhenDetectingInstance)
                Divider()
                SettingsToggleView(
                    title: "Show/Hide with results (experimental)",
                    description: "Show when at least one angle is measured, Hide when no results are present.",
                    option: $settings.ninjabrainBotAutoAppear
                )
                .onChange(of: settings.ninjabrainBotAutoAppear) { newValue in
                    if newValue {
                        try? NinjabrainAdjuster.enableHttpServer()
                    }
                }

                Divider()
                SettingsToggleView(
                    title: "Show Offset Overlay on Eye Projector (experimental)",
                    description: "Show a green dividing line to represent the position of the offset",
                    option: $settings.ninjabrainBotShowOffsetOverlay
                )
                .onChange(of: settings.ninjabrainBotShowOffsetOverlay) { newValue in
                    if newValue {
                        try? NinjabrainAdjuster.enableHttpServer()
                    }
                }
            }
        }
    }
}

#Preview {
    NinjabrainBotSettings()
}
