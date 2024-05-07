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
    
    @State private var isOutside: Bool = false
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: min(instanceManager.rows, shortcutManager.states.count))
    }
    
    var body: some View {
        VStack {
            if screenRecorder.capturePreviews.isEmpty {
                if shortcutManager.instanceIDs.isEmpty {
                    Text("No Minecraft\nInstances Detected")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
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
                .boundsCheck(isOutside: $isOutside) { value in
                    if instanceManager.smartGrid && value {
                        instanceManager.invertGridLayout()
                    }
                }
            }
        }
        .padding(5)
        .onChange(of: instanceManager.smartGrid) { value in
            if value && isOutside {
                instanceManager.invertGridLayout()
            }
        }
        .onChange(of: instanceManager.forceAspectRatio) { _ in
            Task { await screenRecorder.resetAndStartCapture() }
        }
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
                    
                    if instanceManager.isLocked(idx: idx) {
                        Image(systemName: "lock.fill")
                            .scaleEffect(CGSize(width: 2, height: 2))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 27)
                    }
                    
                    VStack {
                        if instanceManager.showInstanceNumbers {
                            Text("\(idx + 1)")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                .padding(.trailing, 4)
                        }
                    }
                    .animation(.easeInOut, value: instanceManager.showInstanceNumbers)
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
