//
//  EyeProjectorView.swift
//  SlackowWall
//
//  Created by Andrew on 5/29/25.
//

import SwiftUI

struct EyeProjectorView: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var instanceManager = InstanceManager.shared

    @ObservedObject private var gridManager = GridManager.shared
    @StateObject var previewRenderer: PreviewRenderer

    @AppSettings(\.instance)
    private var instances
    @AppSettings(\.mode)
    private var mode
    @AppSettings(\.utility)
    private var utility

    init(instance: TrackedInstance) {
        _previewRenderer = StateObject(wrappedValue: PreviewRenderer(instance: instance))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                previewRenderer.instance.eyeProjectorStream.capturePreview
                    .scaleEffect(
                        x: CGFloat(mode.tallWidth ?? 60) / CGFloat(utility.eyeProjectorWidth),
                        y: utility.eyeProjectorHeightScale
                    )
                    .contentShape(Rectangle())
                    .opacity(previewRenderer.isVisible ? 1 : 0)
                    .onAppear {
                        previewRenderer.handleGridAnimation()
                    }

                Image("tall_overlay")
                    .resizable()
                    .frame(minWidth: geo.size.width, maxWidth: geo.size.width)
            }
        }

    }
}
