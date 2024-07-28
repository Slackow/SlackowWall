//
//  KeybindingsSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct KeybindingsSettings: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    
    var body: some View {
        SettingsPageView(title: "Keybinds") {
            SettingsLabel(title: "Global Bindings", description: "These keybinds work system-wide and can be triggered within any application.")
            
            SettingsCardView {
                VStack {
                    HStack {
                        SettingsLabel(title: "Reset", description: "You may need to change this in [OBS](https://obsproject.com) too.", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.resetGKey, defaultValue: .u)
                    }
                    
                    Divider()
                    
                    HStack {
                        SettingsLabel(title: "Toggle Wide Mode", description: "Toggle between two resolutions quickly.", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.planarGKey, defaultValue: nil)
                    }
                    
                    Divider()
                    
                    HStack {
                        SettingsLabel(title: "Toggle Alt Dimension Mode", description: "Toggle between another set of resolutions.", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.altGKey, defaultValue: nil)
                    }
                }
            }
            
            SettingsLabel(title: "In-App Bindings", description: "These keybinds work only within SlackowWall itself.")
                .padding(.top, 5)
            
            SettingsCardView {
                VStack {
                    HStack {
                        SettingsLabel(title: "Reset All", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.resetAllKey, defaultValue: .t)
                    }
                    
                    Divider()
                    
                    HStack {
                        SettingsLabel(title: "Reset Hovered", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.resetOneKey, defaultValue: .e)
                    }
                    
                    Divider()
                    
                    HStack {
                        SettingsLabel(title: "Run Hovered and Reset Others", description: "You may need to change this in [OBS](https://obsproject.com) too.", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.resetOthersKey, defaultValue: .f)
                    }
                    
                    Divider()
                    
                    HStack {
                        SettingsLabel(title: "Run Hovered", description: "You may need to change this in [OBS](https://obsproject.com) too.", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.runKey, defaultValue: .r)
                    }
                    
                    Divider()
                    
                    HStack {
                        SettingsLabel(title: "Lock Hovered", description: "You can also shift click instances to lock/unlock them.", font: .body)
                        
                        KeybindingView(keybinding: $profileManager.profile.lockKey, defaultValue: .c)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            SettingsCardView {
                SettingsButtonView(title: "Restore Defaults", buttonText: "Reset", action: ShortcutManager.shared.resetKeybinds)
            }
        }
    }
}

#Preview {
    KeybindingsSettings()
}
