//
//  ModeSettings.swift
//  SlackowWall
//
//  Created by Kihron on 7/25/24.
//

import SwiftUI

struct ModeSettings: View {
    @StateObject private var viewModel = ModeSettingsViewModel()

    @AppSettings(\.mode) private var settings
    @AppSettings(\.keybinds) private var keybinds
    @AppSettings(\.utility) private var utility

    var body: some View {
        SettingsPageView(title: "Window Resizing", shouldDisableFocus: false) {
            SettingsLabel(
                title: "Dimensions",
                description:
                    "The dimensions of the game windows in different cases.\nCurrent monitor size: [\(viewModel.screenSize)](0), subtracting menu bar and dock: [\(viewModel.visibleScreenSize)](0)."
            )
            .tint(.orange)
            .allowsHitTesting(false)
            .contentTransition(.numericText())
            .animation(.smooth, value: viewModel.visibleScreenSize)
            .padding(.bottom, -6)

            VStack {
                if viewModel.multipleOutOfBounds {
                    Text(
                        .init(
                            "More than one dimension out of bounds is illegal, this will invalidate your run!"
                        )
                    )
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.red)
                }
            }
            .animation(
                .easeInOut.delay(viewModel.multipleOutOfBounds ? 0.3 : 0),
                value: viewModel.multipleOutOfBounds)

            ModeCardView(
                name: "Gameplay",
                description:
                    "The size of the game while you are in an instance, required for other modes to work.\nOptional Keybind goes directly to gameplay, other keybinds toggle their sizes.",
                actualDimensions: Settings[\.self].baseDimensions,
                isGameplayMode: true, isExpanded: true, keybind: $keybinds.baseGKey,
                posHints: ("", ""),
                mode: $settings.baseMode
            )

            ModeCardView(
                name: "Tall",
                description: "Tall is generally used for eye measuring or zoom.",
                actualDimensions: Settings[\.self].tallDimensions(
                    for: TrackingManager.shared.trackedInstances.first),
                keybind: $keybinds.tallGKey,
                mode: $settings.tallMode
            )

            ModeCardView(
                name: "Thin",
                description:
                    "Thin is generally used for buried treasures, preemptive, and/or e-ray.",
                actualDimensions: Settings[\.self].thinDimensions,
                keybind: $keybinds.thinGKey,
                mode: $settings.thinMode
            )

            ModeCardView(
                name: "Wide",
                description: "Wide is generally used for seeing further with planar fog.",
                actualDimensions: Settings[\.self].wideDimensions,
                keybind: $keybinds.planarGKey,
                mode: $settings.wideMode
            )

            ModeCardView(
                name: "Reset",
                description:
                    "Reset is used for wall mode, and is used to make your instances wider so you can see more on the preview.",
                actualDimensions: Settings[\.self].resetDimensions,
                posHints: ("", ""),
                mode: $settings.resetMode
            )
        }
        .animation(
            .smooth.delay(viewModel.multipleOutOfBounds ? 0 : 0.3),
            value: viewModel.multipleOutOfBounds
        )
    }
}

#Preview {
    ScrollView {
        ModeSettings()
            .padding()
    }
}
