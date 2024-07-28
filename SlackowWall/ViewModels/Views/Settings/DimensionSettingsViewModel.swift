//
//  DimensionSettingsViewModel.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI
import Combine

class DimensionSettingsViewModel: ObservableObject {
    private var screenDimensions: CGSize?
    
    private var cancellable: AnyCancellable?
    
    var screenSize: String {
        return screenDimensions?.debugDescription.replacingOccurrences(of: ".0", with: "") ?? "Unknown"
    }
    
    init() {
        self.screenDimensions = NSScreen.main?.visibleFrame.size
        setupScreenChangeNotification()
    }
    
    private func setupScreenChangeNotification() {
        cancellable = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.screenDimensions = NSScreen.main?.visibleFrame.size
                self?.objectWillChange.send()
            }
    }
}
