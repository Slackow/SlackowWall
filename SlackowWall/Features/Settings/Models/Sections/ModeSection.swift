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

        var baseMode: SizeMode = .init(
            width: (NSScreen.main?.frame.width).map(Int.init),
            height: (NSScreen.main?.frame.height).map(Int.init),
            x: 0,
            y: 0
        )

        var wideMode: SizeMode = .init()

        var thinMode: SizeMode = .init()

        var tallMode: SizeMode = .init()
        
        var resetMode: SizeMode = .init()

        init() {}
    }
    struct SizeMode: Codable, Hashable {
        var width: Int? = nil
        var height: Int? = nil
        var x: Int? = nil
        var y: Int? = nil
    }
}
