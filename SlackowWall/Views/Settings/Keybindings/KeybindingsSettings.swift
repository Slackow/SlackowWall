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
        ScrollView {
            VStack(spacing: 12) {
                SettingsLabel(title: "Global Bindings", description: "These keybinds work system-wide and can be triggered within any application.")
                
                SettingsCardView {
                    VStack {
                        HStack {
                            Text("Reset")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            KeybindingView(keybinding: $profileManager.profile.resetGKey, defaultValue: .u)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Toggle Wide Instance")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Toggle between two resolutions quickly.")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .padding(.trailing, 2)
                            }
                            
                            KeybindingView(keybinding: $profileManager.profile.planarGKey, defaultValue: nil)
                        }
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Toggle Tall Instance")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Toggle between another set of resolutions.")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .padding(.trailing, 2)
                            }
                            
                            KeybindingView(keybinding: $profileManager.profile.planar2GKey, defaultValue: nil)
                        }
                    }
                }
                
                SettingsLabel(title: "In-App Bindings", description: "These keybinds work only within SlackowWall itself.")
                    .padding(.top, 5)
                
                SettingsCardView {
                    VStack {
                        HStack {
                            Text("Reset All")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            KeybindingView(keybinding: $profileManager.profile.resetAllKey, defaultValue: .t)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Reset Hovered")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            KeybindingView(keybinding: $profileManager.profile.resetOneKey, defaultValue: .e)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Run Hovered and Reset Others")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            KeybindingView(keybinding: $profileManager.profile.resetOthersKey, defaultValue: .f)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Run Hovered")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            KeybindingView(keybinding: $profileManager.profile.runKey, defaultValue: .r)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Lock Hovered")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("You can also shift click instances to lock/unlock them.")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .padding(.trailing, 2)
                            }
                            KeybindingView(keybinding: $profileManager.profile.lockKey, defaultValue: .c)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                SettingsCardView {
                    SettingsButtonView(title: "Restore Defaults", buttonText: "Reset", action: {
                        profileManager.profile.resetGKey = .u
                        profileManager.profile.resetAllKey = .t
                        profileManager.profile.resetOneKey = .e
                        profileManager.profile.resetOthersKey = .f
                        profileManager.profile.runKey = .r
                        profileManager.profile.lockKey = .c
                    })
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
    }
}

#Preview {
    KeybindingsSettings()
}
