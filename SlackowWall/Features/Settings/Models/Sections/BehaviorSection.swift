//
//  Behavior.swift
//  SlackowWall
//
//  Created by Kihron on 5/4/25.
//

import SwiftUI
import DefaultCodable

extension Preferences {
    @DefaultCodable
    struct BehaviorSection: Codable, Hashable {
        var utilityMode: Bool = true
        var f1OnJoin: Bool = false
        var shouldHideWindows: Bool = true
        var onlyOnFocus: Bool = true
        var checkStateOutput: Bool = false

        var resetMode: ResetMode = .wall

        init() {}
    }
}
