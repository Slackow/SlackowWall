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
        VStack(spacing: 12) {
            SettingsCardView {
                Form {
                    SettingsToggleView(title: "Press F1 on Join", option: $instanceManager.f1OnJoin)
                    
                    Divider()
                    
                    SettingsToggleView(title: "Pause on Lost Focus", description: "Pauses the capture of the instances when SlackowWall is not the focused window.", option: $instanceManager.onlyOnFocus)
                    
                    Divider()
                    
                    SettingsToggleView(title: "Hide Windows", description: "Hide all other instances when you enter an instance for performance, highly recommended.", option: $instanceManager.shouldHideWindows)
                    
                    Divider()
                    
                    SettingsToggleView(title: "Use State Output", description: "Turn this on if you have the state output mod, it prevents an instance from reseting if it is still generating the world", option: $instanceManager.checkStateOutput)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

#Preview {
    BehaviorSettings()
}
