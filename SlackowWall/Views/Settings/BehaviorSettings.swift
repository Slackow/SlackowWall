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
