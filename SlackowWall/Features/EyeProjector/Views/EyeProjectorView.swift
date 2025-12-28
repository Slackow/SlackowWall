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
    
    private var scaleFactor: CGFloat

    init(instance: TrackedInstance) {
        _previewRenderer = StateObject(wrappedValue: PreviewRenderer(instance: instance))
        scaleFactor = instance.info.mods.map(\.id).contains("retino") ? 1 : NSScreen.primary?.backingScaleFactor ?? 1
    }
    
    var overlayImage: Image {
        (utility.eyeProjectorOverlayImage
            .flatMap{NSImage(contentsOf: $0)}
            .flatMap{Image(nsImage: $0)}
         ?? Image("tall_overlay"))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if screenRecorder.eyeProjectorMode == .tall {
                    previewRenderer.instance.eyeProjectorStream.capturePreview
                        .scaleEffect(
                            x: 1,
                            y: utility.eyeProjectorHeightScale * scaleFactor/(384.0/60)
                        )
                    overlayImage
                        .resizable()
                        .frame(width: geo.size.width)
                        .opacity(utility.eyeProjectorOverlayOpacity)
                } else {
                    previewRenderer.instance.eyeProjectorStream.capturePreview
                }
            }
        }
    }
}
