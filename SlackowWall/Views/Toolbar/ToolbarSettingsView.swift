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
        Button(action: { Task { openWindow(id: "settings-window") }}) {
            if isHovered {
                Image(systemName: "gear")
                    .foregroundStyle(Color(nsColor: .labelColor))
            } else {
                Image(systemName: "gear")
            }
        }.onHover {isHovered = $0}
    }
}

#Preview {
    ToolbarSettingsView()
}
