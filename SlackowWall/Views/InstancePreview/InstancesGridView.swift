//
//  InstancesGridView.swift
//  SlackowWall
//
//  Created by Kihron on 1/11/23.
//

import SwiftUI
import ScreenCaptureKit

struct InstancesGridView: View {
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    
    private var showPreviews: Bool {
        return instanceManager.onlyOnFocus ? instanceManager.isActive : true
    }
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: min(instanceManager.rows, shortcutManager.states.count))
    }

    var body: some View {
        Group {
            if screenRecorder.capturePreviews.isEmpty {
                if shortcutManager.instanceIDs.isEmpty {
                    Text("No Minecraft Instances Detected")
                }
            } else {
                if showPreviews {
                    Group {
                        if instanceManager.alignment == .horizontal {
                            LazyHGrid(rows: gridItems, spacing: 8) {
                                gridContent
                            }
                        } else {
                            LazyVGrid(columns: gridItems, spacing: 8) {
                                gridContent
                            }
                        }
                    }
                    .background(PreviewShortcutListener(key: $instanceManager.keyPressed))
                } else {
                    Text("Window out of focus.")
                }
            }
        }
        .padding()
        .task {
            print("Screen Recorder Started!")
            if await screenRecorder.canRecord {
                await screenRecorder.start()
            }
        }
        .onChange(of: instanceManager.isActive) { value in
            if value && instanceManager.onlyOnFocus {
                Task {
                    await screenRecorder.resumeCapture()
                }
            }
        }
    }
    
    private var gridContent: some View {
        ForEach(screenRecorder.capturePreviews.indices, id: \.self) { idx in
            if idx < screenRecorder.capturePreviews.count {
                CapturePreviewView(preview: screenRecorder.capturePreviews[idx], size: screenRecorder.contentSizes[idx], idx: idx)
            }
        }
    }
}

struct InstancePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InstancesGridView()
    }
}
