//
//  WallAlert.swift
//  SlackowWall
//
//  Created by Kihron on 5/20/24.
//

import SwiftUI

enum WallAlert: Error {
    case noScreenPermission, noAccessibilityPermission

    var id: Self {
        return self
    }

    var description: String {
        switch self {
            case .noScreenPermission:
                "SlackowWall currently does not have\npermission to record your screen."
            case .noAccessibilityPermission:
                "SlackowWall currently does not have accessibility permission.\nIf enabled already try removing it and relaunching the app."
        }
    }
}
