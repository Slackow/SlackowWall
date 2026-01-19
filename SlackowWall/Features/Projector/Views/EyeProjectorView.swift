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
    private var f: CGFloat

    init(instance: TrackedInstance) {
        _previewRenderer = StateObject(wrappedValue: PreviewRenderer(instance: instance))
        scaleFactor =
            instance.info.mods.map(\.id).contains("retino")
            ? 1 : NSScreen.primary?.backingScaleFactor ?? 1
        f = NSScreen.primary?.backingScaleFactor ?? 1
    }

    var overlayImage: Image {
        Image(
            utility.eyeProjectorOverlayImage
                .flatMap { NSImage(contentsOf: $0) }
                .flatMap { .nsImage($0) }
                ?? .asset("tall_overlay"))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if screenRecorder.projectorMode == .eye {
                    previewRenderer.instance.eyeProjectorStream.capturePreview
                        .scaleEffect(
                            x: 1,
                            y: utility.eyeProjectorHeightScale * f / 6
                        )
                    overlayImage
                        .resizable()
                        .frame(width: geo.size.width)
                        .opacity(utility.eyeProjectorOverlayOpacity)
                } else if screenRecorder.projectorMode == .pie_and_e {
                    previewRenderer.instance.eyeProjectorStream.capturePreview
                    previewRenderer.instance.eCountProjectorStream.capturePreview
                        .scaleEffect(4 * utility.pieProjectorECountScale / f)
                } else {
                    previewRenderer.instance.eyeProjectorStream.capturePreview
                }
            }
        }
    }
}
