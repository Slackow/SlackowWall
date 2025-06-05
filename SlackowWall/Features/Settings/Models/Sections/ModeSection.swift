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

        var baseWidth: Int? = nil
        var baseHeight: Int? = nil
        var baseX: Int? = nil
        var baseY: Int? = nil

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
