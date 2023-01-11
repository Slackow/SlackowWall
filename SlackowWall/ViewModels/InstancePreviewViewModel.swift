//
//  InstancePreviewViewModel.swift
//  SlackowWall
//
//  Created by Kihron on 1/11/23.
//

import SwiftUI
import ScreenCaptureKit

class InstancePreviewViewModel: ObservableObject {
    
    func getStreams() async {
        let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        
        //guard let window : [SCWindow] = content.windows.first(where: { $0.windowID == windowID }) else { return }
        
    }
}
