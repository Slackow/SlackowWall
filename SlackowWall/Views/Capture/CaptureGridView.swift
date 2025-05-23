//
//  CaptureGridView.swift
//  SlackowWall
//
//  Created by Kihron on 5/8/24.
//

import SwiftUI
import ScreenCaptureKit

struct CaptureGridView: View {
    @ObservedObject private var trackingManager = TrackingManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var gridManager = GridManager.shared
    
    @Namespace private var gridSpace
    
    var body: some View {
        VStack {
            if !trackingManager.isCaptureReady && (!profileManager.profile.utilityMode || trackingManager.trackedInstances.isEmpty) {
                if trackingManager.trackedInstances.isEmpty {
                    Text("No Minecraft\nInstances Detected")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Group {
                    if profileManager.profile.alignment == .horizontal {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<profileManager.profile.sections, id: \.self) { section in
                                HStack(spacing: 0) {
                                    createSection(section: section)
                                    
                                    if gridManager.indicesForSection(section).count < gridManager.maximumItemsPerSection() {
                                        Spacer()
                                            .frame(width: gridManager.sectionSize.width)
                                    }
                                }
                            }
                        }
                    } else {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(0..<profileManager.profile.sections, id: \.self) { section in
                                VStack(spacing: 0) {
                                    createSection(section: section)
                                    
                                    if gridManager.indicesForSection(section).count < gridManager.maximumItemsPerSection() {
                                        Spacer()
                                            .frame(height: gridManager.sectionSize.height)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: profileManager.profile.alignment)
                .animation(.easeInOut, value: profileManager.profile.sections)
                .animation(.smooth, value: trackingManager.trackedInstances.count)
                .background(KeybindListener(key: $instanceManager.keyAction))
            }
        }
        .padding(5)
        .task { await screenRecorder.startCapture() }
        .onChange(of: gridManager.isActive) { value in
            gridManager.handleLostFocus(isActive: value)
        }
        .onChange(of: gridManager.showInfo) { value in
            if !value {
                gridManager.showInstanceInfo()
            }
        }
        .onChange(of: trackingManager.isCaptureReady) { _ in
            gridManager.applyGridAnimation()
        }
        .onAppear {
            gridManager.showInstanceInfo()
        }
    }
    
    private func createSection(section: Int) -> some View {
        ForEach(gridManager.indicesForSection(section), id: \.self) { idx in
            if idx < trackingManager.trackedInstances.count {
                captureContentView(trackedInstance: trackingManager.trackedInstances[idx])
                    .if(section == 0 && idx == 0) { view in
                        view.modifier(SizeReader(size: $gridManager.sectionSize))
                    }
            }
        }
    }
    
    private func captureContentView(trackedInstance: TrackedInstance) -> some View {
        TrackedInstanceView(instance: trackedInstance)
            .id(trackedInstance)
            .matchedGeometryEffect(id: trackedInstance, in: gridSpace)
    }
}

#Preview {
    CaptureGridView()
        .frame(width: 500, height: 500)
}
