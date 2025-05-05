//
//  PersonalizeSection.swift
//  SlackowWall
//
//  Created by Kihron on 5/5/25.
//

import SwiftUI
import DefaultCodable

extension Preferences {
    @DefaultCodable
    struct PersonalizeSection: Codable, Hashable {
        var streamFPS: Double = 15

        var lockMode: LockMode = .preset
        var selectedUserLock: UserLock? = nil
        var selectedLockPreset: LockPreset = .apple
        var lockScale: Double = 1
        var lockAnimation: Bool = true

        init() {}
    }
}
