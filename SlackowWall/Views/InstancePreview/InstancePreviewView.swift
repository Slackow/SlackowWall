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
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
            if !screenRecorder.capturePreviews.isEmpty {
                ForEach(screenRecorder.capturePreviews.indices, id: \.self) { idx in
                    screenRecorder.capturePreviews[idx]
                            .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                            .roundedCorners(radius: 10, corners: .allCorners)
                }
            } else {
                Text("No Minecraft Instances Detected")
            }
        }
        .padding(.horizontal)
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
