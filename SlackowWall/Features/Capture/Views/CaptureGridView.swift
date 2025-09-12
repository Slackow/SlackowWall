//
//  CaptureGridView.swift
//  SlackowWall
//
//  Created by Kihron on 5/8/24.
//

import ScreenCaptureKit
import SwiftUI

struct CaptureGridView: View {
    @ObservedObject private var trackingManager = TrackingManager.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var gridManager = GridManager.shared

    @Namespace private var gridSpace

    @State var quickLaunchOpen = false

    @AppSettings(\.behavior)
    private var behavior
    @AppSettings(\.instance)
    private var instance

    var body: some View {
        VStack {
            if !trackingManager.isCaptureReady
                && (!behavior.utilityMode || trackingManager.trackedInstances.isEmpty)
            {
                if trackingManager.trackedInstances.isEmpty {
                    Spacer()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text("No Minecraft\nInstances Detected")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Button(action: { quickLaunchOpen.toggle() }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundStyle(.green)
                            Text("Quick Launch")
                        }
                    }
                    .foregroundStyle(.white)
                    .sheet(isPresented: $quickLaunchOpen) {
                        PrismQuickLaunchView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Group {
                    if instance.alignment == .horizontal {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<instance.sections, id: \.self) { section in
                                HStack(spacing: 0) {
                                    createSection(section: section)

                                    if gridManager.indicesForSection(section).count
                                        < gridManager.maximumItemsPerSection()
                                    {
                                        Spacer()
                                            .frame(width: gridManager.sectionSize.width)
                                    }
                                }
                            }
                        }
                    } else {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(0..<instance.sections, id: \.self) { section in
                                VStack(spacing: 0) {
                                    createSection(section: section)

                                    if gridManager.indicesForSection(section).count
                                        < gridManager.maximumItemsPerSection()
                                    {
                                        Spacer()
                                            .frame(height: gridManager.sectionSize.height)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: instance.alignment)
                .animation(.easeInOut, value: instance.sections)
                .animation(.smooth, value: trackingManager.trackedInstances.count)
                .background(KeybindListener(key: $instanceManager.keyAction))
            }
        }
        .padding(5)
        .task { await screenRecorder.startCapture() }
        .onChange(of: gridManager.isActive) { _, value in
            gridManager.handleLostFocus(isActive: value)
        }
        .onChange(of: gridManager.showInfo) { _, value in
            if !value {
                gridManager.showInstanceInfo()
            }
        }
        .onChange(of: trackingManager.isCaptureReady) {
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
