//
//  InstancePreviewView.swift
//  SlackowWall
//
//  Created by Kihron on 1/11/23.
//

import SwiftUI
import ScreenCaptureKit

struct InstancePreviewView: View {
    @StateObject private var screenRecorder = ScreenRecorder()
    
    var body: some View {
        LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
            if !screenRecorder.capturePreviews.isEmpty {
                ForEach(screenRecorder.capturePreviews.indices, id: \.self) { idx in
                    Button(action: {
                        screenRecorder.capturePreviews[idx]
                        let pid = ShortcutManager.shared.instanceIDs[idx]

                        let script = "tell application \"System Events\" to set frontmost of the first process whose unix id is \(pid) to true"

                        var error: NSDictionary?
                        if let scriptObject = NSAppleScript(source: script) {
                            scriptObject.executeAndReturnError(&error)
                            ShortcutManager.shared.sendKey(key: 0x35, pid: pid)
                        } else {print("brokey :(")}


//                        if let app = NSRunningApplication(processIdentifier: pid) {
//                            app.activate(options: .activateIgnoringOtherApps)
//                        } else {
//                            print("no app found")
//                        }
                        print("pressed: \(pid) #(\(idx))")
                    }){
                        screenRecorder.capturePreviews[idx]
                            .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                            .roundedCorners(radius: 10, corners: .allCorners)
                    }.buttonStyle(.plain)
                }
            } else {
                Text("No Minecraft Instances Detected")
            }
        }
        .padding(.horizontal)
        .onAppear {
            Task {
                if await screenRecorder.canRecord {
                    await screenRecorder.start()
                }
            }
        }
    }
}

struct InstancePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InstancePreviewView()
    }
}
