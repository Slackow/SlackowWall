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
        var eyeProjectorShouldOpenWithTallMode: Bool {
            eyeProjectorEnabled && eyeProjectorOpenWithTallMode
        }
        var eyeProjectorWidth: Int = 60
        var adjustFor4kScaling: Bool {
            set(value) {
                eyeProjectorWidth = value ? 30 : 60
            }
            get {
                eyeProjectorWidth == 30
            }
        }
        var eyeProjectorHeightScale: Double = 0.2

        var sensitivityScaleEnabled: Bool = false
        var sensitivityScaleToolBarIcon: Bool = false
        var sensitivityScale: Double = 1.0
        var boatEyeSensitivity: Float64 = 0.02291165
        var tallSensitivityScale: Double = 0.25

        init() {}
    }
}
