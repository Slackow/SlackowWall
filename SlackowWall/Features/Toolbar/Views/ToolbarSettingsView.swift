//
//  ToolbarSettingsView.swift
//  SlackowWall
//
//  Created by Kihron on 7/24/24.
//

import SwiftUI

struct ToolbarSettingsView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: { openWindow(id: "settings-window") }) {
            Image(systemName: "gear")
        }
        .onHover { isHovered = $0 }
        .foregroundStyle(Color(nsColor: isHovered ? .labelColor : .secondaryLabelColor))
        .popoverLabel("Settings")
    }
}

#Preview {
    ToolbarSettingsView()
}
