//
//  BoundsChecker.swift
//  SlackowWall
//
//  Created by Kihron on 5/2/24.
//

import SwiftUI

struct BoundsChecker: ViewModifier {
    @Binding var isOutside: Bool
    @State private var windowSize: CGSize = .zero
    var action: ((Bool) -> ())?
    
    @State private var lastFrameChecked: CGRect = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size) { _ in
                            let newFrame = geometry.frame(in: .global)
                            checkBounds(viewFrame: newFrame)
                        }
                        .onChange(of: windowSize) { _ in
                            let newFrame = geometry.frame(in: .global)
                            checkBounds(viewFrame: newFrame)
                        }
                        .onAppear {
                            updateWindowSize()
                            
                            let newFrame = geometry.frame(in: .global)
                            checkBounds(viewFrame: newFrame)
                        }
                }
            )
    }
    
    private func updateWindowSize() {
        if let window = NSApplication.shared.windows.first(where: { $0.title == "SlackowWall" }) {
            windowSize = window.frame.size
            NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { _ in
                windowSize = window.frame.size
            }
        }
    }
    
    private func checkBounds(viewFrame: CGRect) {
        guard lastFrameChecked != viewFrame else {
            return
        }
        
        if viewFrame.maxX > windowSize.width || viewFrame.maxY > windowSize.height ||
            viewFrame.minX < 0 || viewFrame.minY < 0 {
            isOutside = true
        } else {
            isOutside = false
        }

        lastFrameChecked = viewFrame
        action?(isOutside)
    }
}
