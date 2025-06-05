//
//  PrismInstance.swift
//  SlackowWall
//
//  Created by Kihron on 6/5/25.
//

import AppKit
import Foundation

struct PrismInstance: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let icon: NSImage
}
