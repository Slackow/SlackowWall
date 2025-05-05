//
//  ProfileSection.swift
//  SlackowWall
//
//  Created by Kihron on 5/3/25.
//

import SwiftUI
import DefaultCodable

extension Preferences {
    @DefaultCodable
    struct ProfileSection: Codable, Hashable {
        var id: UUID = UUID()
        var name: String = "Main"
        var isActive: Bool = true

        init() {}
    }
}
