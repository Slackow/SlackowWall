//
//  UserLock.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

struct UserLock: Identifiable, Codable, Hashable, Equatable {
    var id: UUID
    var icon: String
    
    func getIconImage() -> NSImage? {
        let fileManager = FileManager.default
        guard let appDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let iconPath = appDirectory.appendingPathComponent("SlackowWall/Icons/").appendingPathComponent(icon)
        return NSImage(contentsOf: iconPath)
    }
    
    static func == (lhs: UserLock, rhs: UserLock) -> Bool {
        return lhs.icon == rhs.icon
    }
}
