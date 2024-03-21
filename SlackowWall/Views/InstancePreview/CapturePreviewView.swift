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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            preview
                .aspectRatio(size, contentMode: .fill)
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
            
            if instanceManager.isLocked(idx: idx) {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.red)
                    .frame(width: 25, height: 30)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 25)
            }
        }
    }
}
