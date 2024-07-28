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
        SettingsLabel(title: "Dimensions", description: "The dimensions of the game windows in different cases. These values should not exceed the current monitor size: [\(viewModel.screenSize)](0).")
            .tint(.orange)
            .allowsHitTesting(false)
            .contentTransition(.numericText())
            .animation(.smooth, value: viewModel.screenSize)
        
        DimensionCardView(name: "Gameplay", description: "The size of the game while you are in an instance, which is required for the other modes to work.", isGameplayMode: true, x: $profileManager.profile.baseX, y: $profileManager.profile.baseY, width: $profileManager.profile.baseWidth, height: $profileManager.profile.baseHeight)
        
        DimensionCardView(name: "Reset", description: "The size the game will be while you are in SlackowWall.", x: $profileManager.profile.resetX, y: $profileManager.profile.resetY, width: $profileManager.profile.resetWidth, height: $profileManager.profile.resetHeight)
        
        DimensionCardView(name: "Wide", description: "The size the game will be when you switch to wide instance mode.", x: $profileManager.profile.wideX, y: $profileManager.profile.wideY, width: $profileManager.profile.wideWidth, height: $profileManager.profile.wideHeight)
        
        DimensionCardView(name: "Alt Dimension", description: "The size the game will be when you switch to alt dimension mode.", x: $profileManager.profile.altX, y: $profileManager.profile.altY, width: $profileManager.profile.altWidth, height: $profileManager.profile.altHeight)
    }
}

#Preview {
    ScrollView {
        DimensionSettings()
            .padding()
    }
}
