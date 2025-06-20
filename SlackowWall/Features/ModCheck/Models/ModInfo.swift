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
    let authors: [String]
    let license: String?
    let icon: String?
    let filePath: URL?
}
