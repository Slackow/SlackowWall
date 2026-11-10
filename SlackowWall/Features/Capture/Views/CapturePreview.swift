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
    private var reframe: ((CapturedFrame, CALayer) -> Void)? = nil
    public mutating func onNewFrame(_ callback: @escaping (CapturedFrame, CALayer) -> Void) {
        self.reframe = callback
    }

    init() {
        contentLayer.contentsGravity = .resizeAspectFill
        contentLayer.magnificationFilter = .nearest
        contentLayer.minificationFilter = .nearest
        contentLayer.allowsEdgeAntialiasing = false
        contentLayer.actions = [
            "contents": NSNull(),
            "contentsRect": NSNull(),
            "bounds": NSNull(),
            "position": NSNull(),
        ]
    }

    func makeNSView(context: Context) -> CaptureVideoPreview {
        CaptureVideoPreview(layer: contentLayer)
    }

    // Called by ScreenRecorder as it receives new video frames.

    static func surfaceSizePixels(_ surface: IOSurfaceRef) -> (w: Int, h: Int) {
        (IOSurfaceGetWidth(surface), IOSurfaceGetHeight(surface))
    }

    mutating func updateFrame(_ frame: CapturedFrame) {
        if let reframe {
            reframe(frame, contentLayer)
            self.reframe = nil
        }
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
