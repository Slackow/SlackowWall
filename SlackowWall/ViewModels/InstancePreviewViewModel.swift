//
//  InstancePreviewViewModel.swift
//  SlackowWall
//
//  Created by Kihron on 1/11/23.
//

import SwiftUI
import ScreenCaptureKit

class InstancePreviewViewModel: ObservableObject {
    
    
    
    func getStreams() async -> SCStream? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            let instances = ShortcutManager.shared.byInstanceNum
            print("instance count: \(instances.count - 1)")
            for i in 1...instances.count {

            }
            guard let window = content.windows.first(where: { instances[1] == $0.owningApplication?.processID}) else { return nil; }
            let contentFilter = SCContentFilter(desktopIndependentWindow: window)
            let streamConfig = SCStreamConfiguration()
            streamConfig.capturesAudio = false
            let stream = SCStream(filter: contentFilter, configuration: streamConfig, delegate: nil)
            return stream;
        } catch { return nil; }
        
    }
}
