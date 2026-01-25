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
        var eyeProjectorOverlayImage: URL? = nil
        var eyeProjectorAlwaysOnTop: Bool = false
        var eyeProjectorTitleBarHidden: Bool = false
        var eyeProjectorShouldOpenWithTallMode: Bool {
            eyeProjectorEnabled && eyeProjectorOpenWithTallMode
        }

        var pieProjectorEnabled: Bool = false
        var pieProjectorOpenWithTallMode: Bool = true
        var pieProjectorOpenWithThinMode: Bool = true
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

        var startupApplicationEnabled: Bool = false
        var startupApplications: [URL] = []

        init() {}
    }
}
