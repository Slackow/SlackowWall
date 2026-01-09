//
//  InstanceState.swift
//  SlackowWall
//
//  Created by Kihron on 5/7/24.
//

import SwiftUI

// Raw values are based on the ascii values of the first characters in the file.
// If the first character is 'i', then the 12th (index 11) character is used instead.

enum InstanceState: UInt8 {
    case waiting = 0x77
    case paused = 0x73
    case unpaused = 0x61
    case inGameScreen = 0x65
    case title = 0x74
    case generating = 0x67
    case previewing = 0x70
}
