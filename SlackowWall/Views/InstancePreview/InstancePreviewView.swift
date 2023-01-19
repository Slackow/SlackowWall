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
                        Button(action: { viewModel.clickInstance(screenRecorder: screenRecorder, idx: idx) }) {
                            screenRecorder.capturePreviews[idx]
                                .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                                .roundedCorners(radius: 10, corners: .allCorners)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
