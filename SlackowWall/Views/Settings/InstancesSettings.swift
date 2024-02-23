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
    
    @AppStorage("moveXOffset") var moveXOffset: String = "0"
    @AppStorage("moveYOffset") var moveYOffset: String = "0"
    
    @State private var stopped = false
    
    @State private var moving = false
    
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
                            Button ("Move Over") {
                                move(forward: true)
                            }.disabled(moving)
                            Button ("Move Back") {
                                move(forward: false)
                            }.disabled(moving)
                            Button ("Set Pos") {
                                move(forward: true, direct: true)
                            }.disabled(moving)
                            TextField("X offset", text: $moveXOffset).frame(width: 90)
                            TextField("Y offset", text: $moveYOffset).frame(width: 90)
                        }
                    }
                }
                .padding()
            }
            .padding(10)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
    func move(forward: Bool, direct: Bool = false) {
        moving = true
        Task {
            let xOff = "\(direct ? "" : "x+")\((Int32(moveXOffset) ?? 0) * (forward ? 1 : -1))"
            let yOff = "\(direct ? "" : "y+")\((Int32(moveYOffset) ?? 0) * (forward ? 1 : -1))"
            let pids = ShortcutManager.shared.instanceIDs.map({"\($0)"}).joined(separator: ",")
            if (xOff == "x+0" && yOff == "y+0") || pids.isEmpty { moving = false;return }
            let fullScript = """
                tell application "System Events"
                    repeat with pid in [\(pids)]
                        repeat with aWindow in (every window of (first process whose unix id is pid))
                            if name of aWindow is not "Window" then \(direct ? "" : "\nset {x, y} to position of aWindow")
                                set position of aWindow to {\(xOff), \(yOff)}
                            end if
                        end repeat
                    end repeat
                end tell
                """
            
            print("\(fullScript)")
            // Execute the AppleScript
            if let appleScript = NSAppleScript(source: fullScript) {
                var errorDict: NSDictionary? = nil
                appleScript.executeAndReturnError(&errorDict)
                if let error = errorDict {
                    print("AppleScript Execution Error: \(error)")
                }
            }
            moving = false
        }
    }
}
