//
//  ResizeBackgroundView.swift
//  SlackowWall
//
//  Created by Codex on 6/1/26.
//

import SwiftUI

struct ResizeBackgroundView: View {
    @ObservedObject private var manager = ResizeBackgroundManager.shared

    @AppSettings(\.mode)
    private var settings

    var body: some View {
        ZStack {
            Color.black

            if let image = manager.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(settings.resizeBackgroundOpacity)
            }
        }
        .clipped()
        .ignoresSafeArea()
    }
}
