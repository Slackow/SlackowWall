//
//  LockPreset.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

enum LockPreset: String, CaseIterable, Identifiable, Hashable, Codable {
    case apple = "lock.fill"
    case minecraft = "minecraft_lock"

    var image: Image {
        switch self {
            case .apple:
                return Image(systemName: rawValue)
            case .minecraft:
                return Image(rawValue)
        }
    }

    var id: Self {
        return self
    }
}
