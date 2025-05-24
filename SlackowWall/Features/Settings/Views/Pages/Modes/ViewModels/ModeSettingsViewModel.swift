//
//  ModeSettingsViewModel.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI
import Combine

class ModeSettingsViewModel: ObservableObject {
    private var screenDimensions: CGSize?

    private var visibleScreenDimensions: CGSize?

    private var cancellable: AnyCancellable?

    var screenSize: String {
        return screenDimensions?.debugDescription.replacingOccurrences(of: ".0", with: "") ?? "Unknown"
    }

    var visibleScreenSize: String {
        return visibleScreenDimensions?.debugDescription.replacingOccurrences(of: ".0", with: "") ?? "Unknown"
    }

    var multipleOutOfBounds: Bool {
        let p = Settings[\.mode]
        let dimensions = [(p.resetWidth, p.resetHeight), (p.baseWidth, p.baseHeight), (p.tallWidth, p.tallHeight), (p.thinWidth, p.thinHeight), (p.wideWidth, p.wideHeight)]
        return dimensions.filter({!WindowController.dimensionsInBounds(width: $0, height: $1)}).count >= 2
    }

    init() {
        self.screenDimensions = NSScreen.main?.frame.size
        self.visibleScreenDimensions = NSScreen.main?.visibleFrame.size
        setupScreenChangeNotification()
    }

    private func setupScreenChangeNotification() {
        cancellable = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.screenDimensions = NSScreen.main?.frame.size
                self?.visibleScreenDimensions = NSScreen.main?.visibleFrame.size
                self?.objectWillChange.send()
            }
    }
}
