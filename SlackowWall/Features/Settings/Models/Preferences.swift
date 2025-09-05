//
//  Preferences.swift
//  SlackowWall
//
//  Created by Kihron on 5/3/25.
//

import DefaultCodable
import SwiftUI

@DefaultCodable
struct Preferences: Codable, Hashable {
    var profile: ProfileSection = .init()
    var instance: InstanceSection = .init()
    var behavior: BehaviorSection = .init()
    var mode: ModeSection = .init()
    var keybinds: KeybindSection = .init()
    var personalize: PersonalizeSection = .init()
    var utility: UtilitySection = .init()

    init() {}
}

extension Preferences {
    var baseDimensions: (CGFloat?, CGFloat?, CGFloat?, CGFloat?) {
        (mode.baseWidth.cg, mode.baseHeight.cg, mode.baseX.cg, mode.baseY.cg)
    }

    var tallDimensions: (CGFloat, CGFloat, CGFloat?, CGFloat?) {
        (
            mode.tallWidth.cg ?? 384,
            mode.tallHeight.cg ?? (utility.adjustFor4kScaling ? 8192 : 16384), mode.tallX.cg,
            mode.tallY.cg
        )
    }

    var thinDimensions: (CGFloat, CGFloat?, CGFloat?, CGFloat?) {
        (
            mode.thinWidth.cg ?? mode.tallWidth.cg ?? 384, mode.thinHeight.cg ?? mode.baseHeight.cg,
            mode.thinX.cg, mode.thinY.cg
        )
    }

    var wideDimensions: (CGFloat?, CGFloat, CGFloat?, CGFloat?) {
        (
            mode.wideWidth.cg ?? mode.baseWidth.cg, mode.wideHeight.cg ?? 300, mode.wideX.cg,
            mode.wideY.cg
        )
    }

    var resetDimensions: (CGFloat?, CGFloat?, CGFloat?, CGFloat?) {
        (
            mode.resetWidth.cg ?? mode.baseWidth.cg, mode.resetHeight.cg ?? mode.baseHeight.cg,
            mode.resetX.cg ?? mode.baseX.cg, mode.baseY.cg
        )
    }
}

extension Int? {
    fileprivate var cg: CGFloat? {
        self.map(CGFloat.init)
    }
}
