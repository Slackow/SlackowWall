//
//  UtilitySection.swift
//  SlackowWall
//
//  Created by Slackow on 5/26/25.
//

import DefaultCodable
import SwiftUI

extension Preferences {
    @DefaultCodable
    struct UtilitySection: Codable, Hashable {
        var autoLaunchPaceman: Bool = false
        var pacemanToolBarIcon: Bool = false

        var eyeProjectorEnabled: Bool = false
        var eyeProjectorOpenWithTallMode: Bool = true
        var eyeProjectorHeightScale: Double = 0.2
        var eyeProjectorOverlayOpacity: Double = 1.0
        var eyeProjectorStretchedOverlay: Bool = false
        var eyeProjectorOverlayImage: URL? = nil
        var eyeProjectorOverlayWidth: Int {
            if eyeProjectorDynamicOverlay {
                return eyeProjectorColumnsPerSide * 2
            }
            return eyeProjectorStretchedOverlay ? 30 : 60
        }
        var eyeProjectorAlwaysOnTop: Bool = false
        var eyeProjectorTitleBarHidden: Bool = false
        var eyeProjectorShouldOpenWithTallMode: Bool {
            eyeProjectorEnabled && eyeProjectorOpenWithTallMode
        }

        // Dynamic overlay (replaces static image when enabled)
        var eyeProjectorDynamicOverlay: Bool = false
        var eyeProjectorColumnsPerSide: Int = 15
        var eyeProjectorOverlayColor1: CodableColor = CodableColor(r: 1.0, g: 0.69, b: 0.77)  // pink
        var eyeProjectorOverlayColor2: CodableColor = CodableColor(r: 0.68, g: 0.85, b: 0.9)  // blue
        var eyeProjectorOverlayTextColor: CodableColor = CodableColor(r: 0, g: 0, b: 0)  // black
        var eyeProjectorOverlayCenterColor: CodableColor = CodableColor(r: 0.8, g: 0.8, b: 0.8)  // gray
        var eyeProjectorOverlayBandOpacity: Double = 1.0
        var eyeProjectorShowDecadeMarkers: Bool = false

        var pieProjectorEnabled: Bool = false
        var pieProjectorOpenWithTallMode: Bool = true
        var pieProjectorOpenWithThinMode: Bool = true
        var pieProjectorFlatten: Bool = false
        var pieProjectorScaleX: Double = 0.7
        var pieProjectorScaleY: Double = 1.4
        var pieProjectorOffsetY: Double = 40
        var pieProjectorECountScale: Double = 1.0
        var pieProjectorECountTranslation: CGSize = .zero
        var pieProjectorECountVisible: Bool = true
        var pieProjectorAlwaysOnTop: Bool = true
        var pieProjectorTitleBarHidden: Bool = true
        var pieProjectorShouldOpenWithTallMode: Bool {
            pieProjectorEnabled && pieProjectorOpenWithTallMode
        }
        var pieProjectorShouldOpenWithThinMode: Bool {
            pieProjectorEnabled && pieProjectorOpenWithThinMode
        }

        var sensitivityScaleEnabled: Bool = false
        var sensitivityScaleToolBarIcon: Bool = false
        var sensitivityScale: Double = 12.8
        var boatEyeSensitivity: Double = 0.02291165
        var tallSensitivityFactorEnabled: Bool = true
        var tallSensitivityFactor: Double = 40

        var ninjabrainBotLocation: URL? = nil
        var ninjabrainBotAutoLaunch: Bool = false
        var ninjabrainBotLaunchWhenDetectingInstance: Bool = false

        var startupApplicationEnabled: Bool = false
        var startupApplications: [URL] = []

        init() {}
    }
}
