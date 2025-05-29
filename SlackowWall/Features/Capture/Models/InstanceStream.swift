//
//  InstanceStream.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import ScreenCaptureKit
import SwiftUI

class InstanceStream {
    var capturePreview: CapturePreview
    var captureFilter: SCContentFilter?
    var captureRect: CGSize

    var streamError: StreamError?

    init() {
        self.capturePreview = CapturePreview()
        self.captureRect = .zero
    }

    func clearCapture() {
        capturePreview = CapturePreview()
        captureFilter = nil
        captureRect = .zero
        streamError = nil
    }
}
