//
//  BehaviorSettings.swift
//  SlackowWall
//
//  Created by Andrew on 4/28/24.
//

import SwiftUI

struct BehaviorSettings: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    
    private var screenSize: String {
        return instanceManager.screenSize?.debugDescription ?? "Unknown"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsCardView {
                    VStack {
                        SettingsToggleView(title: "Press F1 on Join", option: $profileManager.profile.f1OnJoin)
                        
                        Divider()
                        
                        SettingsToggleView(title: "Pause on Lost Focus", description: "Pauses the capture of the instances when SlackowWall is not the focused window.", option: $profileManager.profile.onlyOnFocus)
                        
                        Divider()
                        
                        SettingsToggleView(title: "Hide Windows", description: "Hide all other instances when you enter an instance for performance, highly recommended.", option: $profileManager.profile.shouldHideWindows)
                    }
                }
                
                SettingsCardView {
                    SettingsToggleView(title: "Use State Output", description: "Turn this on if you have the state output mod, it prevents an instance from reseting if it is still generating the world.", option: $profileManager.profile.checkStateOutput)
                }
                
                SettingsLabel(title: "Window Dimensions", description: "The dimensions of the game windows in different cases. These values should not exceed the current monitor size: [\(screenSize)](0).")
                    .tint(.red)
                    .allowsHitTesting(false)
                    .contentTransition(.numericText())
                    .padding(.top, 5)
                
                DimensionCardView(
                    name: "Gameplay",
                    description: "The size the game will be while you are in an instance. This mode is required for the others to work.",
                    x: $profileManager.profile.baseX,
                    y: $profileManager.profile.baseY,
                    width: $profileManager.profile.baseWidth,
                    height: $profileManager.profile.baseHeight
                )
                
                DimensionCardView(name: "Reset", description: "The size the game will be while you are in SlackowWall.", x: $profileManager.profile.resetX, y: $profileManager.profile.resetY, width: $profileManager.profile.resetWidth, height: $profileManager.profile.resetHeight)
                
                DimensionCardView(name: "Wide", description: "The size the game will be when you switch to wide instance mode.", x: $profileManager.profile.wideX, y: $profileManager.profile.wideY, width: $profileManager.profile.wideWidth, height: $profileManager.profile.wideHeight)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .removeFocusOnTap()
    }
}

#Preview {
    BehaviorSettings()
}
