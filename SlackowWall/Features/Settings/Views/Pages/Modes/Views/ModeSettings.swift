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

    var body: some View {
        SettingsPageView(title: "Window Resizing", shouldDisableFocus: false) {
            SettingsLabel(title: "Dimensions", description: "The dimensions of the game windows in different cases.\nCurrent monitor size: [\(viewModel.screenSize)](0), subtracting menu bar and dock: [\(viewModel.visibleScreenSize)](0).")
                .tint(.orange)
                .allowsHitTesting(false)
                .contentTransition(.numericText())
                .animation(.smooth, value: viewModel.visibleScreenSize)
                .padding(.bottom, -6)

            VStack {
                if viewModel.multipleOutOfBounds {
                    Text(.init("More than one dimension out of bounds is illegal, and will invalidate your run!"))
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.red)
                }
            }
            .animation(.easeInOut.delay(viewModel.multipleOutOfBounds ? 0.3 : 0), value: viewModel.multipleOutOfBounds)

            ModeCardView(name: "Gameplay", description: "The size of the game while you are in an instance, required for other modes to work.\nOptional Keybind goes directly to gameplay, other keybinds toggle their sizes.",
                              isGameplayMode: true, keybind: $keybinds.baseGKey, x: $settings.baseX, y: $settings.baseY, width: $settings.baseWidth, height: $settings.baseHeight)

            ModeCardView(name: "Tall", description: "The size the game will be when you switch to tall mode.",
                              keybind: $keybinds.tallGKey, x: $settings.tallX, y: $settings.tallY, width: $settings.tallWidth, height: $settings.tallHeight)

            ModeCardView(name: "Thin", description: "The size the game will be when you switch to thin mode.",
                              keybind: $keybinds.thinGKey, x: $settings.thinX, y: $settings.thinY, width: $settings.thinWidth, height: $settings.thinHeight)

            ModeCardView(name: "Wide", description: "The size the game will be when you switch to wide instance mode.",
                              keybind: $keybinds.planarGKey, x: $settings.wideX, y: $settings.wideY, width: $settings.wideWidth, height: $settings.wideHeight)

            ModeCardView(name: "Reset", description: "The size the game will be while you are in SlackowWall. (For Wall Mode)",
                              x: $settings.resetX, y: $settings.resetY, width: $settings.resetWidth, height: $settings.resetHeight)
        }
        .animation(.smooth.delay(viewModel.multipleOutOfBounds ? 0 : 0.3), value: viewModel.multipleOutOfBounds)
    }
}

#Preview {
    ScrollView {
        ModeSettings()
            .padding()
    }
}
