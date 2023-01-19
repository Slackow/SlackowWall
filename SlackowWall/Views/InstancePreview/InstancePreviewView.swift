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

    var body: some View {
        Group {
            if !screenRecorder.capturePreviews.isEmpty {
                LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(screenRecorder.capturePreviews.indices, id: \.self) { idx in
                        Button(action: { viewModel.openInstance(idx: idx) }) {
                            ZStack(alignment: .topTrailing) {
                                screenRecorder.capturePreviews[idx]
                                    .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
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

                                if viewModel.lockedInstances.contains(viewModel.getInstanceProcess(idx: idx)) {
                                    Image(systemName: "lock.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.red)
                                        .frame(width: 25, height: 30)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 25)
                                }
                            }
                        }
                        .buttonStyle(.plain)
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
}

struct InstancePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        InstancePreviewView()
    }
}
