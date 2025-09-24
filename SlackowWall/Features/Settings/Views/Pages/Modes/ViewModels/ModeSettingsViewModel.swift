//
//  ModeSettingsViewModel.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import Combine
import SwiftUI

class ModeSettingsViewModel: ObservableObject {
    private var screenDimensions: CGSize?

    private var visibleScreenDimensions: CGSize?

    private var cancellable: AnyCancellable?

    var screenSize: String {
        return screenDimensions?.debugDescription.replacingOccurrences(of: ".0", with: "")
            ?? "Unknown"
    }

    var visibleScreenSize: String {
        return visibleScreenDimensions?.debugDescription.replacingOccurrences(of: ".0", with: "")
            ?? "Unknown"
    }

    var multipleOutOfBounds: Bool {
        let p = Settings.shared.preferences
        let dimensions = [
            p.baseDimensions, p.tallDimensions(for: TrackingManager.shared.trackedInstances.first), p.thinDimensions, p.wideDimensions, p.resetDimensions
        ]
        return dimensions.filter({(w, h, _, _) in
            !WindowController.dimensionsInBounds(width: w.map(Int.init), height: h.map(Int.init)) })
            .count >= 2
    }

    init() {
        self.screenDimensions = NSScreen.primary?.frame.size
        self.visibleScreenDimensions = NSScreen.primary?.visibleFrame.size
        setupScreenChangeNotification()
    }

    private func setupScreenChangeNotification() {
        cancellable = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.screenDimensions = NSScreen.primary?.frame.size
                self?.visibleScreenDimensions = NSScreen.primary?.visibleFrame.size
                self?.objectWillChange.send()
            }
    }
}
