//
//  PacemanConfig.swift
//  SlackowWall
//
//  Created by Andrew on 5/27/25.
//

import DefaultCodable
import Foundation

@DefaultCodable
struct PacemanConfig: Codable {
    var accessKey: String = ""
    var enabledForPlugin: Bool = false
    var allowAnyWorldName: Bool = false
    var resetStatsEnabled: Bool = true

    init() {}
}
