//
//  InstancePreviewView.swift
//  SlackowWall
//
//  Created by Kihron on 1/11/23.
//

import SwiftUI
import ScreenCaptureKit

struct InstancePreviewView: View {
    @StateObject var screenRecorder = ScreenRecorder()
    
    var body: some View {
        HStack{
            screenRecorder.capturePreview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                .padding(8)
        }
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
