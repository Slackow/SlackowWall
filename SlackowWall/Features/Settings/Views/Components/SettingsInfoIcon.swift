//
//  SettingsInfoIcon.swift
//  SlackowWall
//
//  Created by Andrew on 6/9/25.
//

import SwiftUI

struct SettingsInfoIcon: View {
    var description: String
    var body: some View {
        Image(systemName: "info.circle.fill")
            .popoverLabel(description)
    }
}

#Preview {
    SettingsInfoIcon(description: "Hi")
}
