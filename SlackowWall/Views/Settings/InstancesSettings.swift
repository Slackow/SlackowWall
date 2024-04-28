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
        VStack(spacing: 12) {
            SettingsLabel(title: "Direction", description: "Control the grid layout of the instance previews in the main window.")
            
            SettingsCardView {
                VStack {
                    Picker("", selection: $instanceManager.alignment) {
                        ForEach(Alignment.allCases, id: \.self) { type in
                            Text(type == .vertical ? "Columns" : "Rows").tag(type)
                        }
                    }.pickerStyle(.segmented)
                    
                    Picker("", selection: $instanceManager.rows) {
                        ForEach(1..<10) {
                            Text("\($0)").tag($0)
                        }
                    }.pickerStyle(.segmented)
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Switch Columns and Rows")
                            Text("Switch columns and rows and adjust based on number of instances, fixes instances being off screen")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 2)
                        
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action:{
                            let instanceCount = shortcutManager.instanceIDs.count
                            let rows = instanceManager.rows
                            var newRows = (instanceCount + rows - 1) / rows
                            if newRows < 1 { newRows = 1 }
                            if newRows > 9 { newRows = 9 }
                            instanceManager.rows = newRows
                            instanceManager.alignment = instanceManager.alignment == .vertical ? .horizontal : .vertical
                            
                            
                            
                        }) {
                            Text("Flip")
                        }
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .padding(.leading)
                            .disabled( shortcutManager.instanceIDs.isEmpty)
                    }
                    Divider()
                    SettingsToggleView(title: "Show Instance Numbers", option: $instanceManager.showInstanceNumbers)
                    
                }
                .labelsHidden()
            }
            
            SettingsLabel(title: "Control Panel")
                .padding(.top, 5)
            
            SettingsCardView {
                VStack(alignment: .leading) {
                    HStack {
                        
                        Button(action: { [self] in
                            stopped = true
                            shortcutManager.killAll()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                exit(0)
                            }
                        }) {
                            if !stopped {
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.red)
                            }
                            Text(stopped ? "Goodbye!" : "Stop Instances")
                        }
                        .disabled(stopped)
                        Text("(\(shortcutManager.instanceIDs.count))")
                        Text("Close all instances and SlackowWall")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    
                    Divider()
                    
                    HStack {
                        Button(action: { instanceManager.copyMods()
                        }) {
                            Text("Sync Mods")
                        }
                        .disabled(shortcutManager.instanceIDs.count < 2)
                        Text("Copy mods from first instance to all open instances (closes them)")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    
                    Divider()
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
                        Spacer()
                        Text("Adjust Instance Positions,\nwidth and height are optional")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.gray)

                    }
                    Form {
                        HStack {
                            TextField("X", text: $instanceManager.moveXOffset)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Y", text: $instanceManager.moveYOffset)
                                .textFieldStyle(.roundedBorder)
                            TextField("W", text:
                                $instanceManager
                                .setWidth)
                            .textFieldStyle(.roundedBorder)
                            TextField("H", text:
                                $instanceManager
                                .setHeight)
                            .textFieldStyle(.roundedBorder)
                        }.padding(.leading, 50)
                    
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
    }
}

#Preview {
    InstancesSettings()
}
