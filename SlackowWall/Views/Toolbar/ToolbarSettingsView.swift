//
//  ToolbarSettingsView.swift
//  SlackowWall
//
//  Created by Kihron on 7/24/24.
//

import SwiftUI

struct ToolbarSettingsView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button(action: { Task { openWindow(id: "settings-window") }}) {
            Image(systemName: "gear")
        }
    }
}

#Preview {
    ToolbarSettingsView()
}
