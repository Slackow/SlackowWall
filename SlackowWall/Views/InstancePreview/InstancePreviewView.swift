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
    @ObservedObject private var instanceManager = InstanceManager.shared
    
    @State private var isActive: Bool = true

    var body: some View {
        Group {
            if !screenRecorder.capturePreviews.isEmpty {
                if isActive {
                    Group {
                        if instanceManager.alignment == .horizontal {
                            LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: instanceManager.rows), spacing: 8) {
                                content
                            }
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: instanceManager.rows), spacing: 8) {
                                content
                            }
                        }
                    }
                    .background(PreviewShortcutListener(key: $instanceManager.keyPressed))
                } else {
                    Text("Window out of focus.")
                }
            } else {
                Text("No Minecraft Instances Detected")
            }
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            isActive = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            isActive = false
        }
        .onAppear {
            Task {
                if await screenRecorder.canRecord {
                    await screenRecorder.start()
                }
            }
        }
        .onChange(of: isActive) { value in
            Task {
                if value {
                    await screenRecorder.resumeCapture()
                } else {
                    await screenRecorder.stop()
                }
            }
        }
    }

    var content: some View {
        ForEach(screenRecorder.capturePreviews.indices, id: \.self) { idx in
            ZStack(alignment: .topTrailing) {
                screenRecorder.capturePreviews[idx]
                    .aspectRatio(screenRecorder.contentSizes[idx], contentMode: .fit)
                    .roundedCorners(radius: 10, corners: .allCorners)
                    .overlay(PreviewActionsListener(lockAction: { key in
                            if key.modifierFlags.contains(.shift) {
                                instanceManager.lockInstance(idx: idx)
                            }
                    }))
                    .onHover { isHovered in
                        if isHovered {
                            instanceManager.hoveredInstance = idx
                        }  else {
                            instanceManager.hoveredInstance = nil
                        }
                    }
                    .onChange(of: instanceManager.keyPressed) { _ in
                        instanceManager.handleKeyEvent(idx: idx)
                    }

                if instanceManager.isLocked(idx: idx) {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                        .frame(width: 25, height: 30)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 25)
                }
               //Text("\(idx)")
            }
        }
    }
}

struct InstancePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InstancePreviewView()
    }
}
