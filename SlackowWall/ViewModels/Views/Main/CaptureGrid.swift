//
//  CaptureGrid.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI

class CaptureGrid: ObservableObject {
    @Published var sectionSize: CGSize = .zero
    @Published var animateGrid: Bool = false
    
    @Published var isActive: Bool = true
    @Published var showInfo: Bool = false
    
    static let shared = CaptureGrid()
    
    init() {
        
    }
    
    @MainActor func handleLostFocus(isActive: Bool) {
        if ProfileManager.shared.profile.onlyOnFocus {
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
        let baseItemsPerSection = totalPreviews / ProfileManager.shared.profile.sections
        let extraItems = totalPreviews % ProfileManager.shared.profile.sections
        
        let startIndex = section * baseItemsPerSection + min(section, extraItems)
        var endIndex = startIndex + baseItemsPerSection
        if section < extraItems {
            endIndex += 1
        }
        
        return startIndex..<endIndex
    }
    
    @MainActor func maximumItemsPerSection() -> Int {
        let totalPreviews = TrackingManager.shared.trackedInstances.count
        let sections = ProfileManager.shared.profile.sections
        return Int(ceil(Double(totalPreviews) / Double(sections)))
    }
    
    func showInstanceInfo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.smooth) {
                self.showInfo = true
            }
        }
    }
    
    func handleGridAnimation() {
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
}
