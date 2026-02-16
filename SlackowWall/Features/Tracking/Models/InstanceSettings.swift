//
//  InstanceSettings.swift
//  SlackowWall
//
//  Created by Andrew on 2/8/26.
//

import DefaultCodable
import Foundation

@DefaultCodable
struct InstanceSettings: Codable {

    var checkBoateye: Bool? = nil
    var autoFixNinjabrainBot: Bool = false
    var autoWorldClearing: Bool = false
    var autoUpdateMods: Bool = false
    var quitAppOnInstanceClose: Bool = false
    var lastWorldClear: Date = .distantPast

    init() {}

    static func load(for info: InstanceInfo) throws -> Self {
        let path = InstanceSettings.path(for: info)
        let read = try Data(contentsOf: path)
        return try JSONDecoder().decode(Self.self, from: read)
    }

    func save(for info: InstanceInfo) throws {
        let path = InstanceSettings.path(for: info)
        let jsonData = try JSONEncoder().encode(self)
        try jsonData.write(to: path)
    }

    private static func path(for info: InstanceInfo) -> URL {
        URL(filePath: "\(info.path)/.slackowwall.json")
    }
}
