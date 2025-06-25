//
//  ModInfo.swift
//  SlackowWall
//
//  Created by Kihron on 6/19/25.
//

import SwiftUI

struct ModInfo: Identifiable, Codable {
    let id: String
    let version: String
    let name: String
    let description: String?
    var authors: [Author] = []
    let license: String?
    let icon: String?
    var filePath: URL?
}

struct Author: Codable {
    var name: String

    init(name: String) {
        self.name = name
    }

    init(from decoder: any Decoder) throws {
        if let name = try? decoder.singleValueContainer().decode(String.self) {
            self = Author(name: name)
        } else {
            let objectContainer = try decoder.container(keyedBy: CodingKeys.self)
            let name = try objectContainer.decode(String.self, forKey: .name)
            self = Author(name: name)
        }
    }
}
