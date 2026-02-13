//
//  InstanceSettings.swift
//  SlackowWall
//
//  Created by Andrew on 2/8/26.
//

import DefaultCodable
import Foundation

@DefaultCodable
struct InstanceSettings: Codable {

    var autoFixNinjabrainBot: Bool = false
    var autoWorldClearing: Bool = false
    var autoUpdateMods: Bool = false
    var quitAppOnInstanceClose: Bool = false

    init() {}
}
