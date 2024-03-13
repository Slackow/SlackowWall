//
//  SettingsOption.swift
//  SwiftAA
//
//  Created by Kihron on 2/23/24.
//

import SwiftUI

protocol SettingsOption: CaseIterable, Identifiable, Hashable {
    var label: String { get }
}
