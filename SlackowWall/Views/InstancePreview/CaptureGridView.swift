//
//  CaptureGridView.swift
//  SlackowWall
//
//  Created by Kihron on 5/8/24.
//

import SwiftUI
import ScreenCaptureKit

struct CaptureGridView: View {
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
                        if instanceManager.alignment == .horizontal {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(0..<instanceManager.sections, id: \.self) { section in
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
                                ForEach(0..<instanceManager.sections, id: \.self) { section in
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
                    .animation(.easeInOut, value: instanceManager.alignment)
                    .animation(.easeInOut, value: instanceManager.sections)
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
    }
    
    private func captureContentView(index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Text("Instance \(index + 1)")
                .padding(.trailing, 4)
            
            CapturePreviewView(preview: screenRecorder.capturePreviews[index], size: screenRecorder.contentSizes[index], idx: index)
            
            if instanceManager.isLocked(idx: index) {
                Image(systemName: "lock.fill")
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 27)
            }
            
            VStack {
                if instanceManager.showInstanceNumbers {
                    Text("\(index + 1)")
                        .foregroundColor(.white)
                        .padding(4)
                }
            }
            .animation(.easeInOut, value: instanceManager.showInstanceNumbers)
        }
        .matchedGeometryEffect(id: "Instance-\(index)", in: gridSpace)
    }
    
    private func indicesForSection(_ section: Int) -> Range<Int> {
        let totalPreviews = screenRecorder.capturePreviews.count
        let baseItemsPerSection = totalPreviews / instanceManager.sections
        let extraItems = totalPreviews % instanceManager.sections
        
        let startIndex = section * baseItemsPerSection + min(section, extraItems)
        var endIndex = startIndex + baseItemsPerSection
        if section < extraItems {
            endIndex += 1
        }
        
        return startIndex..<endIndex
    }
    
    private func maximumItemsPerSection() -> Int {
        let totalPreviews = screenRecorder.capturePreviews.count
        let sections = instanceManager.sections
        return Int(ceil(Double(totalPreviews) / Double(sections)))
    }
}

#Preview {
    CaptureGridView()
        .frame(width: 200, height: 200)
}
