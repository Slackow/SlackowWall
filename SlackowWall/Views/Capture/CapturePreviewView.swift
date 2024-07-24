//
//  CapturePreviewView.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI

struct CapturePreviewView: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    
    @ObservedObject private var captureGrid = CaptureGrid.shared
    
    @ObservedObject var instance: TrackedInstance
    
    @State private var actualSize: CGSize = .zero
    @State private var animateAppearance = false
    
    private let titleBarHeight: CGFloat = 30
    
    private var adjustedTitlebarHeight: CGFloat {
        guard actualSize.height > 0 else { return titleBarHeight }
        let heightScaleFactor = actualSize.height / instance.stream.captureRect.height
        return titleBarHeight * heightScaleFactor
    }
    
    private var scaleFactor: CGFloat {
        let aspectRatioWidth = instance.stream.captureRect.height * 16.0 / 9
        return min(1.0, aspectRatioWidth / instance.stream.captureRect.width)
    }
    
    private var scaledDimensions: CGSize {
        let aspectRatioWidth = instance.stream.captureRect.height * 16.0 / 9
        return CGSize(width: min(aspectRatioWidth, instance.stream.captureRect.width), height: instance.stream.captureRect.height)
    }
    
    var body: some View {
        instance.stream.capturePreview
            .aspectRatio(profileManager.profile.forceAspectRatio ? scaledDimensions : instance.stream.captureRect, contentMode: .fit)
            .scaleEffect(CGSize(width: profileManager.profile.forceAspectRatio ? scaleFactor : 1.0, height: 1.0))
            .modifier(SizeReader(size: $actualSize))
            .mask {
                RoundedRectangle(cornerRadius: 10)
                    .padding(.top, adjustedTitlebarHeight)
            }
            .padding(.top, -adjustedTitlebarHeight)
            .contentShape(Rectangle())
            .opacity(animateAppearance ? 1 : 0)
            .overlay(PreviewActionsListener(lockAction: { key in
                if key.modifierFlags.contains(.shift) {
                    instance.toggleLock()
                }
            }))
            .onHover { isHovered in
                if isHovered {
                    instanceManager.hoveredInstance = instance
                } else {
                    instanceManager.hoveredInstance = nil
                }
            }
            .onChange(of: instanceManager.keyAction) { _ in
                instanceManager.handleKeyEvent(instance: instance)
            }
            .onAppear {
                if captureGrid.animateGrid {
                    if let index = TrackingManager.shared.trackedInstances.firstIndex(where: { $0 == instance }) {
                        let delay = Double(index) * 0.07
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            withAnimation(.smooth) {
                                animateAppearance = true
                            }
                        }
                    }
                } else {
                    animateAppearance = true
                }
            }
    }
}
