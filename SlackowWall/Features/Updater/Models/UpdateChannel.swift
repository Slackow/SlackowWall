//
//  UpdateChannel.swift
//  SwiftAA
//
//  Created by Kihron on 3/10/25.
//

import SwiftUI

enum UpdateChannel: String, SettingsOption {
    case release
    case beta

    var id: String { rawValue }

    var label: String {
        switch self {
            case .release:
                return "Release"
            case .beta:
                return "Beta"
        }
    }
}
