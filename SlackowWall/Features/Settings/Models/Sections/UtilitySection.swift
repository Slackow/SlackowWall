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

        var eyeProjectorEnabled: Bool = false
        var eyeProjectorOpenWithTallMode: Bool = true
        var eyeProjectorShouldOpenWithTallMode: Bool {
            return eyeProjectorEnabled && eyeProjectorOpenWithTallMode
        }
        var eyeProjectorWidth: Int = 60
        var eyeProjectorHeightScale: Double = 0.2

        var sensitivityScaleEnabled: Bool = false
        var sensitivityScale: Double = 1.0
        var tallSensitivityScale: Double = 1.0

        init() {}
    }
}
