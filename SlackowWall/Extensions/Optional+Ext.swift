//
//  Optional+Ext.swift
//  SlackowWall
//
//  Created by Kihron on 3/13/24.
//

import SwiftUI

extension Optional: @retroactive RawRepresentable where Wrapped: Codable {
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return json
    }
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let value = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = value
    }
    
    public func clone() -> Self? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let json = String(data: data, encoding: .utf8) 
        else {
            return "[]"
        }
        return json
    }
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let array = try? JSONDecoder().decode([Element].self, from: data) 
        else {
            return nil
        }
        self = array
    }
}
