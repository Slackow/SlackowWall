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
                }
                .labelsHidden()
            }
            
            SettingsLabel(title: "Control Panel")
                .padding(.top, 5)
            
            SettingsCardView {
                VStack(alignment: .leading) {
                    HStack {
                        Text(stopped ? "Goodbye!" : "Stop Instances (\(shortcutManager.instanceIDs.count)) ")
                        
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: { [self] in
                            stopped = true
                            shortcutManager.killAll()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                exit(0)
                            }
                        }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .disabled(stopped)
                    }
                    Divider()
                    
                    SettingsToggleView(title: "Press F1 on Join", option: $instanceManager.f1OnJoin)
                    
                    Divider()
                    
                    SettingsToggleView(title: "Pause on Lost Focus", description: "Pauses the capture of the instances when SlackowWall is not the focused window.", option: $instanceManager.onlyOnFocus)
                    
                    Divider()
                    
                    HStack {
                        Button(action: { instanceManager.copyMods() }) {
                            Text("Copy Mods from first instance to all")
                        }
                        .disabled(shortcutManager.instanceIDs.count < 2)
                    }
                    
                    Divider()
                    
                    HStack {
                        Button(action: { instanceManager.move(forward: true) }) {
                            Text("Move Over")
                        }
                        .disabled(instanceManager.moving)
                        
                        Button(action: { instanceManager.move(forward: false) }) {
                            Text("Move Back")
                        }
                        .disabled(instanceManager.moving)
                        
                        Button(action: { instanceManager.move(forward: true, direct: true) }) {
                            Text("Set Position")
                        }
                        .disabled(instanceManager.moving)
                        
                        Spacer()
                        
                        Form {
                            HStack {
                                TextField("X", text: $instanceManager.moveXOffset)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Y", text: $instanceManager.moveYOffset)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.leading, 25)
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
