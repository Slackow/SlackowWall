//
//  InstancesSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct InstancesSettings: View {
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsLabel(title: "Grid Layout", description: "Control the grid layout of the instance previews in the main window.")
                
                SettingsCardView {
                    VStack {
                        Group {
                            Picker("", selection: $instanceManager.alignment) {
                                ForEach(Alignment.allCases, id: \.self) { type in
                                    Text(type == .vertical ? "Columns" : "Rows").tag(type)
                                }
                            }
                            
                            Picker("", selection: $instanceManager.rows) {
                                ForEach(1..<10) {
                                    Text("\($0)").tag($0)
                                }
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                
                SettingsCardView {
                    VStack {
                        SettingsToggleView(title: "Smart Grid", description: "Automatically manages the grid layout of the instances to ensure that they all fit properly within an equivalent view.", option: $instanceManager.smartGrid)
                        
                        Divider()
                            .padding(.bottom, 4)
                            
                        SettingsButtonView(title: "Switch Columns and Rows", description: "Switch rows and columns and adjust based on the number of instances to fix layouts that stretch offscreen.", buttonText: "Flip", action: instanceManager.invertGridLayout)
                            .disabled(instanceManager.smartGrid)
                    }
                }
                
                SettingsCardView {
                    VStack {
                        SettingsToggleView(title: "Force Aspect Ratio (16:9)", description: "Forces the instances to use this aspect ratio which is useful when using stretched instances.", option: $instanceManager.forceAspectRatio)
                        
                        Divider()
                            .padding(.bottom, 4)
                        
                        SettingsToggleView(title: "Show Instance Numbers", option: $instanceManager.showInstanceNumbers)
                    }
                }
                
                SettingsLabel(title: "Control Panel")
                    .padding(.top, 5)
                
                SettingsCardView {
                    VStack {
                        SettingsButtonView(title: "Stop All (\(shortcutManager.instanceIDs.count))", description: "Closes all currently tracked instances, Prism, and **SlackowWall** itself.", action: instanceManager.stopAll) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .disabled(instanceManager.isStopping)
                        .contentTransition(.numericText())
                        .animation(.linear, value: shortcutManager.instanceIDs.count)
                        
                        Divider()
                            .padding(.bottom, 4)
                        
                        SettingsButtonView(title: "Copy Mods to All", description: "Copies all mods from the first instance to all other open instances. This operation will close all instances.", buttonText: "Sync", action: instanceManager.copyMods)
                            .disabled(shortcutManager.instanceIDs.count < 2)
                    }
                }
                
                SettingsCardView {
                    VStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Adjust Instances")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(.init("Modify the position, and optionally the width and height, of currently tracked instances."))
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Form {
                            HStack {
                                Group {
                                    TextField("X", text: $instanceManager.moveXOffset)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    TextField("Y", text: $instanceManager.moveYOffset)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    TextField("W", text: $instanceManager.setWidth)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    TextField("H", text: $instanceManager.setHeight)
                                        .textFieldStyle(.roundedBorder)
                                }
                                .frame(width: 80)
                                
                                Button(action: { instanceManager.move(forward: true, direct: true) }) {
                                    Text("Adjust")
                                }
                                .disabled(instanceManager.moving || shortcutManager.instanceIDs.isEmpty)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .removeFocusOnTap()
    }
}

#Preview {
    InstancesSettings()
        .frame(width: 600, height: 500)
}
