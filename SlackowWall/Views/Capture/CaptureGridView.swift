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
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    
    @ObservedObject private var viewModel = CaptureGrid.shared
    @Namespace private var gridSpace
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if !trackingManager.isCaptureReady {
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
                                        ForEach(viewModel.indicesForSection(section), id: \.self) { idx in
                                            if idx < trackingManager.trackedInstances.count {
                                                if section == 0 && idx == 0 {
                                                    captureContentView(trackedInstance: trackingManager.trackedInstances[idx])
                                                        .modifier(SizeReader(size: $viewModel.sectionSize))
                                                } else {
                                                    captureContentView(trackedInstance: trackingManager.trackedInstances[idx])
                                                }
                                            }
                                        }
                                        
                                        if viewModel.indicesForSection(section).count < viewModel.maximumItemsPerSection() {
                                            Spacer()
                                                .frame(width: viewModel.sectionSize.width)
                                        }
                                    }
                                }
                            }
                        } else {
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(0..<profileManager.profile.sections, id: \.self) { section in
                                    VStack(spacing: 0) {
                                        ForEach(viewModel.indicesForSection(section), id: \.self) { idx in
                                            if idx < trackingManager.trackedInstances.count {
                                                if section == 0 && idx == 0 {
                                                    captureContentView(trackedInstance: trackingManager.trackedInstances[idx])
                                                        .modifier(SizeReader(size: $viewModel.sectionSize))
                                                } else {
                                                    captureContentView(trackedInstance: trackingManager.trackedInstances[idx])
                                                }
                                            }
                                        }
                                        
                                        if viewModel.indicesForSection(section).count < viewModel.maximumItemsPerSection() {
                                            Spacer()
                                                .frame(height: viewModel.sectionSize.height)
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
                    .background(PreviewShortcutListener(key: $instanceManager.keyAction))
                }
            }
            .padding(5)
            .task {
                LogManager.shared.appendLog("Attempting to start screen capture...")
                if await screenRecorder.canRecord {
                    await screenRecorder.resetAndStartCapture()
                }
            }
            .onChange(of: viewModel.isActive) { value in
                viewModel.handleLostFocus(isActive: value)
            }
            .onChange(of: viewModel.showInfo) { value in
                if !value {
                    viewModel.showInstanceInfo()
                }
            }
            .onChange(of: trackingManager.isCaptureReady) { _ in
                viewModel.handleGridAnimation()
            }
            .onAppear {
                viewModel.showInstanceInfo()
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
