//
//  ToolbarUtilityModeView.swift
//  SlackowWall
//
//  Created by Andrew on 4/24/25.
//

import SwiftUI

struct ToolbarUtilityModeView: View {
    @State private var isHovered: Bool = false

    @AppSettings(\.behavior)
    private var settings

    var body: some View {
        Button("", systemImage: settings.utilityMode ? "hammer.fill" : "rectangle.grid.3x2") {
            settings.utilityMode.toggle()
            // Reset capture system when utility mode is toggled
            Task {
                // The notification will handle the alert state changes
                await ScreenRecorder.shared.resetAndStartCapture()
            }
        }
        .foregroundStyle(Color(nsColor: isHovered ? .labelColor : .secondaryLabelColor))
        .popoverLabel(
            Text(settings.utilityMode ? "Utility Mode / " : "Wall Mode / ")
                + Text(settings.utilityMode ? "Wall Mode" : "Utility Mode").foregroundColor(.gray)
        )
        .onHover { isHovered = $0 }
    }
}
