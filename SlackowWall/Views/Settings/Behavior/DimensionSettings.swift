//
//  WindowDimensionSettings.swift
//  SlackowWall
//
//  Created by Kihron on 7/25/24.
//

import SwiftUI

struct DimensionSettings: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @StateObject private var viewModel = DimensionSettingsViewModel()
    
    var body: some View {
        SettingsPageView(title: "Window Resizing", shouldDisableFocus: false) {
            SettingsLabel(title: "Dimensions", description: "The dimensions of the game windows in different cases.\nCurrent monitor size: [\(viewModel.screenSize)](0), subtracting menu bar and dock: [\(viewModel.visibleScreenSize)](0).")
                .tint(.orange)
                .allowsHitTesting(false)
                .contentTransition(.numericText())
                .animation(.smooth, value: viewModel.visibleScreenSize)
            let p = profileManager.profile
            let dimensions = [(p.resetWidth, p.resetHeight), (p.baseWidth, p.baseHeight), (p.tallWidth, p.tallHeight), (p.thinWidth, p.thinHeight), (p.wideWidth, p.wideHeight)]
            
            let multipleOOB = dimensions.filter({!WindowController.dimensionsInBounds(width: $0, height: $1)}).count >= 2
            Text(.init("More than one dimension out of bounds is illegal, and will invalidate your run!"))
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.red)
                .opacity(multipleOOB ? 1 : 0)
                .animation(.easeInOut, value: multipleOOB)
            
            
            DimensionCardView(name: "Gameplay", description: "The size of the game while you are in an instance, required for other modes to work.\nOptional Keybind goes directly to gameplay, other keybinds toggle their sizes.",
                              isGameplayMode: true, keybind: p.$baseGKey, x: p.$baseX, y: p.$baseY, width: p.$baseWidth, height: p.$baseHeight)
            
            DimensionCardView(name: "Tall", description: "The size the game will be when you switch to tall mode.",
                              keybind: p.$tallGKey, x: p.$tallX, y: p.$tallY, width: p.$tallWidth, height: p.$tallHeight)
            
            DimensionCardView(name: "Thin", description: "The size the game will be when you switch to thin mode.",
                              keybind: p.$thinGKey, x: p.$thinX, y: p.$thinY, width: p.$thinWidth, height: p.$thinHeight)
            
            DimensionCardView(name: "Wide", description: "The size the game will be when you switch to wide instance mode.",
                              keybind: p.$planarGKey, x: p.$wideX, y: p.$wideY, width: p.$wideWidth, height: p.$wideHeight)

            DimensionCardView(name: "Reset", description: "The size the game will be while you are in SlackowWall. (For Wall Mode)",
                              x: p.$resetX, y: p.$resetY, width: p.$resetWidth, height: p.$resetHeight)
        }
    }
}

#Preview {
    ScrollView {
        DimensionSettings()
            .padding()
    }
}
