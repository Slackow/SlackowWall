//
//  CapturePreview.swift
//  SlackowWall
//
//  Created by Kihron on 1/12/23.
//

import SwiftUI

struct CapturePreview: NSViewRepresentable {

    // A layer that renders the video contents.
    private let contentLayer = CALayer()

    init() {
        contentLayer.contentsGravity = .resizeAspectFill
        contentLayer.magnificationFilter = .nearest
        contentLayer.minificationFilter = .nearest
        contentLayer.allowsEdgeAntialiasing = false
    }

    func makeNSView(context: Context) -> CaptureVideoPreview {
        CaptureVideoPreview(layer: contentLayer)
    }

    // Called by ScreenRecorder as it receives new video frames.
    func updateFrame(_ frame: CapturedFrame) {
        contentLayer.contents = frame.surface
    }

    // The view isn't updatable. Updates to the layer's content are done in outputFrame(frame:).
    func updateNSView(_ nsView: CaptureVideoPreview, context: Context) {
        nsView.layer?.magnificationFilter = .nearest
        nsView.layer?.minificationFilter = .nearest
        nsView.layer?.allowsEdgeAntialiasing = false
    }

    class CaptureVideoPreview: NSView {
        // Create the preview with the video layer as the backing layer.
        init(layer: CALayer) {
            super.init(frame: .zero)

            // Make this a layer-hosting view. First set the layer, then set wantsLayer to true.
            self.layer = layer
            wantsLayer = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
