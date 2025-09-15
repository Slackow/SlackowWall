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
        let m = mode.baseMode
        return (m.width.cg, m.height.cg, m.x.cg, m.y.cg)
    }

    var tallDimensions: (CGFloat, CGFloat, CGFloat?, CGFloat?) {
        let m = mode.tallMode
        return (
            m.width.cg ?? 384,
            m.height.cg ?? (utility.adjustFor4kScaling ? 8192 : 16384),
            m.x.cg,
            m.y.cg
        )
    }

    var thinDimensions: (CGFloat, CGFloat?, CGFloat?, CGFloat?) {
        let m = mode.thinMode
        let tm = mode.tallMode
        let bm = mode.baseMode
        return (
            m.width.cg ?? tm.width.cg ?? 384,
            m.height.cg ?? bm.height.cg,
            m.x.cg,
            m.y.cg
        )
    }

    var wideDimensions: (CGFloat?, CGFloat, CGFloat?, CGFloat?) {
        let m = mode.wideMode
        let bm = mode.baseMode
        return (
            m.width.cg ?? bm.width.cg,
            m.height.cg ?? 300,
            m.x.cg,
            m.y.cg
        )
    }

    var resetDimensions: (CGFloat?, CGFloat?, CGFloat?, CGFloat?) {
        let m = mode.resetMode
        let bm = mode.baseMode
        return (
            m.width.cg ?? bm.width.cg,
            m.height.cg ?? bm.height.cg,
            m.x.cg ?? bm.x.cg,
            m.x.cg ?? bm.y.cg
        )
    }
}

extension Int? {
    fileprivate var cg: CGFloat? {
        self.map(CGFloat.init)
    }
}
