//
//  ModeSection.swift
//  SlackowWall
//
//  Created by Kihron on 5/4/25.
//

import DefaultCodable
import SwiftUI

extension Preferences {
    @DefaultCodable
    struct ModeSection: Codable, Hashable {
        var resetWidth: Int? = nil
        var resetHeight: Int? = nil
        var resetX: Int? = nil
        var resetY: Int? = nil

        var baseWidth: Int? = (NSScreen.main?.frame.width).map(Int.init)
        var baseHeight: Int? = (NSScreen.main?.frame.height).map(Int.init)
        var baseX: Int? = 0
        var baseY: Int? = 0

        var wideWidth: Int? = nil
        var wideHeight: Int? = nil
        var wideX: Int? = nil
        var wideY: Int? = nil

        var thinWidth: Int? = nil
        var thinHeight: Int? = nil
        var thinX: Int? = nil
        var thinY: Int? = nil

        var tallWidth: Int? = nil
        var tallHeight: Int? = nil
        var tallX: Int? = nil
        var tallY: Int? = nil

        init() {}
    }
}
