//
//  CaptureGridView.swift
//  SlackowWall
//
//  Created by Kihron on 5/8/24.
//

import SwiftUI
import ScreenCaptureKit

struct CaptureGridView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    
    @State private var sectionSize: CGSize = .zero
    @Namespace private var gridSpace
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if screenRecorder.capturePreviews.isEmpty {
                    if shortcutManager.instanceIDs.isEmpty {
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
                                        ForEach(indicesForSection(section), id: \.self) { idx in
                                            if section == 0 && idx == 0 {
                                                captureContentView(index: idx)
                                                    .modifier(SizeReader(size: $sectionSize))
                                            } else {
                                                captureContentView(index: idx)
                                            }
                                        }
                                        
                                        if indicesForSection(section).count < maximumItemsPerSection() {
                                            Spacer()
                                                .frame(width: sectionSize.width)
                                        }
                                    }
                                }
                            }
                        } else {
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(0..<profileManager.profile.sections, id: \.self) { section in
                                    VStack(spacing: 0) {
                                        ForEach(indicesForSection(section), id: \.self) { idx in
                                            if section == 0 && idx == 0 {
                                                captureContentView(index: idx)
                                                    .modifier(SizeReader(size: $sectionSize))
                                            } else {
                                                captureContentView(index: idx)
                                            }
                                        }
                                        
                                        if indicesForSection(section).count < maximumItemsPerSection() {
                                            Spacer()
                                                .frame(height: sectionSize.height)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut, value: profileManager.profile.alignment)
                    .animation(.easeInOut, value: profileManager.profile.sections)
                    .background(PreviewShortcutListener(key: $instanceManager.keyPressed))
                }
            }
            .padding(5)
            .task {
                print("Screen Recorder Started!")
                if await screenRecorder.canRecord {
                    await screenRecorder.resetAndStartCapture()
                }
            }
            .onChange(of: instanceManager.isActive) { value in
                if profileManager.profile.onlyOnFocus {
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
            .onChange(of: instanceManager.showInfo) { value in
                if !value {
                    instanceManager.showInstanceInfo()
                }
            }
            .onChange(of: screenRecorder.capturePreviews.count) { value in
                instanceManager.handleGridAnimation(value: value)
            }
            .onAppear {
                instanceManager.showInstanceInfo()
            }
        }
    }
    
    private func captureContentView(index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            CapturePreviewView(preview: screenRecorder.capturePreviews[index], size: screenRecorder.contentSizes[index], idx: index)
                .background {
                    Text("Instance \(index + 1)")
                        .padding(.trailing, 4)
                        .opacity(instanceManager.showInfo ? 1 : 0)
                }
            
            if instanceManager.isLocked(idx: index) {
                Image(systemName: "lock.fill")
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 27)
                    .opacity(instanceManager.showInfo ? 1 : 0)
                    .animation(.easeInOut, value: instanceManager.showInfo)
            }
            
            VStack {
                if profileManager.profile.showInstanceNumbers {
                    Text("\(index + 1)")
                        .foregroundColor(.white)
                        .padding(4)
                }
            }
            .opacity(instanceManager.showInfo ? 1 : 0)
            .animation(.easeInOut, value: instanceManager.showInfo)
            .animation(.easeInOut, value: profileManager.profile.showInstanceNumbers)
        }
        .matchedGeometryEffect(id: "Instance-\(index)", in: gridSpace)
    }
    
    private func indicesForSection(_ section: Int) -> Range<Int> {
        let totalPreviews = screenRecorder.capturePreviews.count
        let baseItemsPerSection = totalPreviews / profileManager.profile.sections
        let extraItems = totalPreviews % profileManager.profile.sections
        
        let startIndex = section * baseItemsPerSection + min(section, extraItems)
        var endIndex = startIndex + baseItemsPerSection
        if section < extraItems {
            endIndex += 1
        }
        
        return startIndex..<endIndex
    }
    
    private func maximumItemsPerSection() -> Int {
        let totalPreviews = screenRecorder.capturePreviews.count
        let sections = profileManager.profile.sections
        return Int(ceil(Double(totalPreviews) / Double(sections)))
    }
}

#Preview {
    CaptureGridView()
        .frame(width: 500, height: 500)
}
