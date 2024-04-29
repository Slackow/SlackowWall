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
    
    @State private var stopped = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsLabel(title: "Direction", description: "Control the grid layout of the instance previews in the main window.")
                
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
                        SettingsButtonView(title: "Switch Columns and Rows", description: "Switch columns and rows and adjust based on number of instances, fixes instances being off screen.", buttonText: "Flip", action: invertGridLayout)
                            .disabled( shortcutManager.instanceIDs.isEmpty)
                        
                        Divider()
                        
                        SettingsToggleView(title: "Show Instance Numbers", option: $instanceManager.showInstanceNumbers)
                    }
                }
                
                SettingsLabel(title: "Control Panel")
                    .padding(.top, 5)
                
                SettingsCardView {
                    VStack {
                        SettingsButtonView(title: "Stop All (\(shortcutManager.instanceIDs.count))", description: "Closes all currently tracked instances, Prism, and **SlackowWall** itself.", action: stopAll) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .disabled(stopped)
                        .contentTransition(.numericText())
                        .animation(.linear, value: shortcutManager.instanceIDs.count)
                        
                        Divider()
                        
                        SettingsButtonView(title: "Copy Mods to All", description: "Copies all mods from the first instance to all other open instances. This operation will close all modified instances.", buttonText: "Sync", action: instanceManager.copyMods)
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
                                TextField("X", text: $instanceManager.moveXOffset)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Y", text: $instanceManager.moveYOffset)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("W", text: $instanceManager.setWidth)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("H", text: $instanceManager.setHeight)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding()
                        
                        HStack {
                            Button(action: { instanceManager.move(forward: true) }) {
                                Text("Move Over")
                            }
                            .disabled(instanceManager.moving || shortcutManager.instanceIDs.isEmpty)
                            
                            Button(action: { instanceManager.move(forward: false) }) {
                                Text("Move Back")
                            }
                            .disabled(instanceManager.moving || shortcutManager.instanceIDs.isEmpty)
                            
                            Button(action: { instanceManager.move(forward: true, direct: true) }) {
                                Text("Set Position")
                            }
                            .disabled(instanceManager.moving || shortcutManager.instanceIDs.isEmpty)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
    }
    
    private func stopAll() {
        stopped = true
        shortcutManager.killAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exit(0)
        }
    }
    
    private func invertGridLayout() {
        let instanceCount = shortcutManager.instanceIDs.count
        let rows = instanceManager.rows
        var newRows = (instanceCount + rows - 1) / rows
        if newRows < 1 { newRows = 1 }
        if newRows > 9 { newRows = 9 }
        instanceManager.rows = newRows
        instanceManager.alignment = instanceManager.alignment == .vertical ? .horizontal : .vertical
    }
}

#Preview {
    InstancesSettings()
        .frame(width: 600, height: 500)
}
