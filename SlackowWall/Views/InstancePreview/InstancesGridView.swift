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
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: min(instanceManager.rows, shortcutManager.states.count))
    }

    var body: some View {
        VStack {
            if screenRecorder.capturePreviews.isEmpty {
                if shortcutManager.instanceIDs.isEmpty {
                    Text("No Minecraft Instances Detected")
                }
            } else {
                Group {
                    if instanceManager.alignment == .horizontal {
                        LazyHGrid(rows: gridItems, spacing: 0) {
                            gridContent
                        }
                    } else {
                        LazyVGrid(columns: gridItems, spacing: 0) {
                            gridContent
                        }
                    }
                }
                .background(PreviewShortcutListener(key: $instanceManager.keyPressed))
            }
        }
        .padding(5)
        .task {
            print("Screen Recorder Started!")
            if await screenRecorder.canRecord {
                await screenRecorder.start()
            }
        }
        .onChange(of: instanceManager.isActive) { value in
            if instanceManager.onlyOnFocus {
                if value {
                    Task {
                        await screenRecorder.resumeCapture()
                    }
                } else {
                    Task {
                        await screenRecorder.stop()
                    }
                }
            }
        }
    }
    
    private var gridContent: some View {
        ForEach(screenRecorder.capturePreviews.indices, id: \.self) { idx in
            if idx < screenRecorder.capturePreviews.count {
                ZStack {
                    Text("Instance \(idx + 1)")
                    CapturePreviewView(preview: screenRecorder.capturePreviews[idx], size: screenRecorder.contentSizes[idx], idx: idx)
                }
            }
        }
    }
}

struct InstancePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InstancesGridView()
    }
}
