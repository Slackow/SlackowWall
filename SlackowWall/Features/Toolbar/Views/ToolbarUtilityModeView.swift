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
        Button(action: {
            settings.utilityMode.toggle()
            // Reset capture system when utility mode is toggled
            Task {
                // The notification will handle the alert state changes
                await ScreenRecorder.shared.resetAndStartCapture()
            }
        }) {
            Image(systemName: "hammer\(settings.utilityMode ? ".fill" : "")")
                .foregroundStyle(Color(nsColor: isHovered ? .labelColor : .secondaryLabelColor))
        }
        .popoverLabel("Utility Mode")
        .onHover { isHovered = $0 }
    }
}
