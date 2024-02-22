//
//  InstancePreviewView.swift
//  SlackowWall
//
//  Created by Kihron on 1/11/23.
//

import SwiftUI
import ScreenCaptureKit

struct InstancePreviewView: View {
    @StateObject private var screenRecorder = ScreenRecorder()
    @ObservedObject private var viewModel = PreviewViewModel()

    @AppStorage("rows") var rows: Int = AppDefaults.rows
    @AppStorage("alignment") var alignment: Alignment = AppDefaults.alignment
    
    @Environment(\.isFocused) var isFocused

    var body: some View {
        Group {
            if !isFocused {
                Text("Window out of focus")
            } else if !screenRecorder.capturePreviews.isEmpty {
                Group {
                    if alignment == .horizontal {
                        LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: rows), spacing: 8) {
                            content
                        }
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: rows), spacing: 8) {
                            content
                        }
                    }
                }
                .background(PreviewShortcutListener(key: $viewModel.keyPressed))
            } else {
                Text("No Minecraft Instances Detected")
            }
        }
        .padding()
        .onAppear {
            Task {
                if await screenRecorder.canRecord {
                    await screenRecorder.start()
                }
            }
        }
    }

    var content: some View {
        ForEach(screenRecorder.capturePreviews.indices, id: \.self) { idx in
            ZStack(alignment: .topTrailing) {
                screenRecorder.capturePreviews[idx]
                    .aspectRatio(screenRecorder.contentSizes[idx], contentMode: .fit)
                    .roundedCorners(radius: 10, corners: .allCorners)
                    .overlay(PreviewActionsListener(lockAction: {
                        viewModel.lockInstance(idx: idx)
                    }))
                    .onHover { isHovered in
                        if isHovered {
                            viewModel.hoveredInstance = idx
                        }  else {
                            viewModel.hoveredInstance = nil
                        }
                    }
                    .onChange(of: viewModel.keyPressed) { _ in
                        viewModel.handleKeyEvent(idx: idx)
                    }

                if viewModel.isLocked(idx: idx) {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                        .frame(width: 25, height: 30)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 25)
                }
               // Text("\(ShortcutManager.shared.states[idx].state)")
            }
        }
    }
}

struct InstancePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InstancePreviewView()
    }
}
