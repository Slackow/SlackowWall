//
//  CapturePreviewView.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI

struct CapturePreviewView: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared

    @ObservedObject private var gridManager = GridManager.shared
    @StateObject var previewRenderer: PreviewRenderer

    @AppSettings(\.instance)
    private var instance

    init(instance: TrackedInstance) {
        _previewRenderer = StateObject(wrappedValue: PreviewRenderer(instance: instance))
    }

    var body: some View {
        previewRenderer.instance.stream.capturePreview
            .aspectRatio(
                instance.forceAspectRatio
                    ? previewRenderer.scaledDimensions
                    : previewRenderer.instance.stream.captureRect, contentMode: .fit
            )
            .scaleEffect(
                CGSize(
                    width: instance.forceAspectRatio ? previewRenderer.scaleFactor : 1.0,
                    height: 1.0)
            )
            .modifier(SizeReader(size: $previewRenderer.actualSize))
            .mask {
                RoundedRectangle(cornerRadius: 10)
                    .padding(.top, previewRenderer.adjustedTitlebarHeight)
            }
            .padding(.top, -previewRenderer.adjustedTitlebarHeight)
            .contentShape(Rectangle())
            .opacity(previewRenderer.isVisible ? 1 : 0)
            .overlay(
                MouseListener(action: { key in
                    if key.modifierFlags.contains(.shift) {
                        previewRenderer.instance.toggleLock()
                    }
                })
            )
            .onHover { isHovered in
                if isHovered {
                    instanceManager.hoveredInstance = previewRenderer.instance
                } else {
                    instanceManager.hoveredInstance = nil
                }
            }
            .onChange(of: instanceManager.keyAction) { _ in
                instanceManager.handleKeyEvent(instance: previewRenderer.instance)
            }
            .onAppear {
                previewRenderer.handleGridAnimation()
            }
    }
}
