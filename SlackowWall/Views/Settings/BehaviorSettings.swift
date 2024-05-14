//
//  BehaviorSettings.swift
//  SlackowWall
//
//  Created by Andrew on 4/28/24.
//

import SwiftUI

struct BehaviorSettings: View {
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsCardView {
                    VStack {
                        SettingsToggleView(title: "Press F1 on Join", option: $instanceManager.f1OnJoin)
                        
                        Divider()
                        
                        SettingsToggleView(title: "Pause on Lost Focus", description: "Pauses the capture of the instances when SlackowWall is not the focused window.", option: $instanceManager.onlyOnFocus)
                        
                        Divider()
                        
                        SettingsToggleView(title: "Hide Windows", description: "Hide all other instances when you enter an instance for performance, highly recommended.", option: $instanceManager.shouldHideWindows)
                    }
                }
                
                SettingsCardView {
                    SettingsToggleView(title: "Use State Output", description: "Turn this on if you have the state output mod, it prevents an instance from reseting if it is still generating the world.", option: $instanceManager.checkStateOutput)
                }
                
                SettingsLabel(title: "Window Dimensions", description: "Dimensions of game windows in different cases, shouldn't exceed monitor size: \(NSScreen.main?.visibleFrame.size.debugDescription ?? "Unknown")")
                    .padding(.top, 5)
                
                DimensionCard(name: "Reset", description: "The size the game will be while you are in SlackowWall", x: $instanceManager.resetX, y: $instanceManager.resetY, width: $instanceManager.resetWidth, height: $instanceManager.resetHeight)
                
                DimensionCard(name: "Gameplay", description: "The size the game will be while you are in an instance", x: $instanceManager.baseX, y: $instanceManager.baseY, width: $instanceManager.baseWidth, height: $instanceManager.baseHeight)
                
                DimensionCard(name: "Wide", description: "The size the game will be when you switch to wide instance mode", x: $instanceManager.wideX, y: $instanceManager.wideY, width: $instanceManager.wideWidth, height: $instanceManager.wideHeight)
                
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
