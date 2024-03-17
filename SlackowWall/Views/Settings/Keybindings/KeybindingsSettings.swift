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
                        
                        KeybindingView(keybinding: $keybindingManager.resetGKey)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Reset All")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.resetAllKey)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Reset Hovered")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.resetOneKey)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Run and Reset Others")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.resetOthersKey)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Run")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        KeybindingView(keybinding: $keybindingManager.runKey)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Lock Hovered")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("You can also shift click instances to lock/unlock")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 2)
                        }
                        KeybindingView(keybinding: $keybindingManager.lockKey)
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
