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
        init() {}
    }
}
