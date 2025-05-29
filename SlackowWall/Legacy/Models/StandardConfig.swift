//
//  StandardConfig.swift
//  SlackowWall
//
//  Created by Andrew on 3/21/24.
//

class StandardConfig: Codable {
    var name: String
    var parent: StandardConfig?
    // Add other configurations here, like volume, difficulty, etc.

    init(name: String, parent: StandardConfig? = nil) {
        self.name = name
        self.parent = parent
    }
}
