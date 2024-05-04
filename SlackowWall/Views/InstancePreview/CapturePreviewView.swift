//
//  CapturePreviewView.swift
//  SlackowWall
//
//  Created by Kihron on 3/13/24.
//

import SwiftUI

struct CapturePreviewView: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    
    var preview: CapturePreview
    var size: CGSize
    var idx: Int
    
    private var scaleFactor: CGFloat {
        let aspectRatioWidth = size.height * 16.0 / 9
        return min(1.0, aspectRatioWidth / size.width)
    }
    
    private var scaledDimensions: CGSize {
        let aspectRatioWidth = size.height * 16.0 / 9
        return CGSize(width: min(aspectRatioWidth, size.width), height: size.height)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            preview
                .aspectRatio(instanceManager.forceAspectRatio ? scaledDimensions : size, contentMode: .fill)
                .overlay(PreviewActionsListener(lockAction: { key in
                    if key.modifierFlags.contains(.shift) {
                        instanceManager.lockInstance(idx: idx)
                    }
                }))
                .onHover { isHovered in
                    if isHovered {
                        instanceManager.hoveredInstance = idx
                    } else {
                        instanceManager.hoveredInstance = nil
                    }
                }
                .onChange(of: instanceManager.keyPressed) { _ in
                    instanceManager.handleKeyEvent(idx: idx)
                }
        }
        .scaleEffect(CGSize(width: instanceManager.forceAspectRatio ? scaleFactor : 1.0, height: 1.0))
    }
}
