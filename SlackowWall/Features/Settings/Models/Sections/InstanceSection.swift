//
//  InstanceSection.swift
//  SlackowWall
//
//  Created by Kihron on 5/3/25.
//

import SwiftUI
import DefaultCodable

extension Preferences {
    @DefaultCodable
    struct InstanceSection: Codable, Hashable {
        var sections: Int = 2
        var alignment: Alignment = .horizontal

        var showInstanceNumbers = true
        var forceAspectRatio = false

        var moveXOffset: Int? = nil
        var moveYOffset: Int? = nil

        var setWidth: Int? = nil
        var setHeight: Int? = nil

        init() {}
    }
}
