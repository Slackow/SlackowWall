//
//  KeybindingsSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct KeybindingsSettings: View {
    @ObservedObject private var keybindingManager = KeybindingManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            SettingsCardView {
                Form {
                    HStack {
                        Text("Reset (Global)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.resetGKey, defaultValue: .keypad0)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Toggle Wide Instance (Global)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Toggle between two resolutions quickly")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 2)
                        }
                        
                        KeybindingView(keybinding: $keybindingManager.planarGKey, defaultValue: nil)
                    }
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Toggle Tall Instance (Global)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Toggle between another set of resolutions")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 2)
                        }
                        
                        KeybindingView(keybinding: $keybindingManager.planar2GKey, defaultValue: nil)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Reset All")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.resetAllKey, defaultValue: .t)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Reset Hovered")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.resetOneKey, defaultValue: .e)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Run Hovered and Reset Others")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.resetOthersKey, defaultValue: .f)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Run Hovered")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.runKey, defaultValue: .r)
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
                        KeybindingView(keybinding: $keybindingManager.lockKey, defaultValue: .c)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            SettingsCardView {
                HStack {
                    Text("Restore Defaults")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(role: .destructive, action: {
                        keybindingManager.resetGKey = .keypad0
                        keybindingManager.resetAllKey = .t
                        keybindingManager.resetOneKey = .e
                        keybindingManager.resetOthersKey = .f
                        keybindingManager.runKey = .r
                        keybindingManager.lockKey = .c
                    }) {
                        Text("Reset")
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

#Preview {
    KeybindingsSettings()
}
