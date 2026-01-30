//
//  ReleaseEntry.swift
//  SwiftAA
//
//  Created by Kihron on 3/8/24.
//

import SwiftUI

struct ReleaseEntry: Identifiable, Codable, Hashable {
    var id: Int
    var tagName: String
    var publishedAt: Date
    var message: String
    var prerelease: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case message = "body"
        case tagName = "tag_name"
        case publishedAt = "published_at"
        case prerelease
    }
}
