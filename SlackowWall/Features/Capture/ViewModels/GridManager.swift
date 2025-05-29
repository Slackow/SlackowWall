//
//  GridManager.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI

class GridManager: ObservableObject, Manager, RefreshObserver {
    @Published var sectionSize: CGSize = .zero
    @Published var animateGrid: Bool = false

    @Published var isActive: Bool = true
    @Published var showInfo: Bool = false

    static let shared = GridManager()

    init() {

    }

    @MainActor func handleLostFocus(isActive: Bool) {
        if Settings[\.behavior].onlyOnFocus {
            if isActive {
                Task {
                    await ScreenRecorder.shared.resumeCapture()
                }
            } else {
                Task {
                    await ScreenRecorder.shared.stop()
                }
            }
        }
    }

    @MainActor func indicesForSection(_ section: Int) -> Range<Int> {
        let totalPreviews = TrackingManager.shared.trackedInstances.count
        let baseItemsPerSection = totalPreviews / Settings[\.instance].sections
        let extraItems = totalPreviews % Settings[\.instance].sections

        let startIndex = section * baseItemsPerSection + min(section, extraItems)
        var endIndex = startIndex + baseItemsPerSection
        if section < extraItems {
            endIndex += 1
        }

        return startIndex..<endIndex
    }

    @MainActor func maximumItemsPerSection() -> Int {
        let totalPreviews = TrackingManager.shared.trackedInstances.count
        let sections = Settings[\.instance].sections
        return Int(ceil(Double(totalPreviews) / Double(sections)))
    }

    func showInstanceInfo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.smooth) {
                self.showInfo = true
            }
        }
    }

    func applyGridAnimation() {
        let count = TrackingManager.shared.trackedInstances.count

        if count > 0 {
            animateGrid = true

            let delay = (Double(count) * 0.07) + 0.07
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.animateGrid = false
            }
        } else {
            animateGrid = false
        }
    }

    func handleRefreshNotification() async throws {

    }
}
