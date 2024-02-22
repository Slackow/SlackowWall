//
//  InstancesSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/29/23.
//

import SwiftUI

struct InstancesSettings: View {
    
    
    @AppStorage("rows") var rows: Int = AppDefaults.rows
    @AppStorage("alignment") var alignment: Alignment = AppDefaults.alignment
    @AppStorage("f1OnJoin") var f1OnJoin: Bool = false
    @AppStorage("fullscreen") var fullscreen: Bool = false
    
    @AppStorage("moveXOffset") var moveXOffset: String = "0"
    @AppStorage("moveYOffset") var moveYOffset: String = "0"
    
    @State private var stopped = false
    
    var body: some View {
        HStack(spacing: 10) {
            SettingsCardView(title: "Configuration") {
                Form {
                    VStack(alignment: .leading) {
                        VStack {
                            HStack {
                                Text("Direction")
                                
                                Picker("", selection: $alignment) {
                                    ForEach(Alignment.allCases, id: \.self) { type in
                                        Text(type == .vertical ? "Columns" : "Rows").tag(type)
                                    }
                                }.pickerStyle(.segmented)
                            }
                            
                            Picker("", selection: $rows) {
                                ForEach(1..<10) {
                                    Text("\($0)").tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        Divider()
                        HStack {
                            Text(stopped ? "Goodbye!" : "Stop Instances (\(ShortcutManager.shared.instanceIDs.count)): ")
                            
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: { [self] in
                                stopped = true
                                ShortcutManager.shared.killAll()
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
                        
                        HStack {
                            Text("Press F1 on join:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("", isOn: $f1OnJoin)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                        Divider()
                        
                        HStack {
                            Text("Play in Fullscreen")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Toggle("", isOn: $fullscreen)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        Divider()
                        
                        HStack {
                            Button ("Move Over") {
                                for pid in ShortcutManager.shared.instanceIDs {
                                    let script = """
                                        tell application "System Events"
                                            repeat with aWindow in (every window of (first process whose unix id is \(pid)))
                                                set {x, y} to position of aWindow
                                                set newPosition to {x + \(Int32(moveXOffset) ?? 0), y + \(Int32(moveYOffset) ?? 0)}
                                                set position of aWindow to newPosition
                                            end repeat
                                        end tell
                                """
                                    
                                    // Execute the AppleScript
                                    if let appleScript = NSAppleScript(source: script) {
                                        var errorDict: NSDictionary? = nil
                                        appleScript.executeAndReturnError(&errorDict)
                                        if let error = errorDict {
                                            print("AppleScript Execution Error: \(error)")
                                        }
                                    }
                                }
                            }
                            TextField("x offset", text: $moveXOffset).frame(width: 90)
                            TextField("y offset", text: $moveYOffset).frame(width: 90)
                        }
                    }
                }
                .padding()
            }
            .padding(10)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
