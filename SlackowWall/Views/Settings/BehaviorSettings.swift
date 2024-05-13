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
                
                SettingsLabel(title: "Window Dimensions", description: "Dimensions of game windows in different cases.")
                    .padding(.top, 5)
                
                SettingsCardView {
                    Form {
                        VStack {
                            HStack {
                                Text("Reset Size")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextField("W", value: $instanceManager.resetWidth, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                
                                TextField("H", value: $instanceManager.resetHeight, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                            
                            HStack {
                                Text("Gameplay Size")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextField("W", value: $instanceManager.baseWidth, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                
                                TextField("H", value: $instanceManager.baseHeight, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                            
                            HStack {
                                Text("Wide Size")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextField("W", value: $instanceManager.wideWidth, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                
                                TextField("H", value: $instanceManager.wideHeight, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
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
