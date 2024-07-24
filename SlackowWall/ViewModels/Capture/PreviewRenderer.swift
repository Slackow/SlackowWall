//
//  PreviewRenderer.swift
//  SlackowWall
//
//  Created by Kihron on 7/24/24.
//

import SwiftUI

class PreviewRenderer: ObservableObject {
    @Published var actualSize: CGSize = .zero
    @Published var isVisible = false
    
    let instance: TrackedInstance
    private let titleBarHeight: CGFloat = 30
    
    init(instance: TrackedInstance) {
        self.instance = instance
    }
    
    var capturePreview: some View {
        instance.stream.capturePreview
    }
    
    var captureRect: CGSize {
        instance.stream.captureRect
    }
    
    var scaledDimensions: CGSize {
        CGSize(width: min(aspectRatioWidth, captureRect.width), height: captureRect.height)
    }
    
    var scaleFactor: CGFloat {
        min(1.0, aspectRatioWidth / captureRect.width)
    }
    
    var adjustedTitlebarHeight: CGFloat {
        guard actualSize.height > 0 else { return titleBarHeight }
        let heightScaleFactor = actualSize.height / captureRect.height
        return titleBarHeight * heightScaleFactor
    }
    
    private var aspectRatioWidth: CGFloat {
        instance.stream.captureRect.height * 16.0 / 9
    }
    
    func handleGridAnimation() {
        if GridManager.shared.animateGrid {
            if let index = TrackingManager.shared.trackedInstances.firstIndex(where: { $0 == instance }) {
                let delay = Double(index) * 0.07
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.smooth) {
                        self.isVisible = true
                    }
                }
            }
        } else {
            isVisible = true
        }
    }
}
