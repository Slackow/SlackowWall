//
//  InstanceStates.swift
//  SlackowWall
//
//  Created by Kihron on 5/7/24.
//

import SwiftUI

struct InstanceStates {
    private init() {}
    
    static let waiting: UInt8 = 0x77
    static let paused: UInt8 = 0x73
    static let unpaused: UInt8 = 0x61
    static let inGameScreen: UInt8 = 0x65
    static let title: UInt8 = 0x74
    static let generating: UInt8 = 0x67
    static let previewing: UInt8 = 0x70
}
