//
//  ToolbarUtilityModeView.swift
//  SlackowWall
//
//  Created by Andrew on 4/24/25.
//

import SwiftUI

struct ToolbarUtilityModeView: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: {
            Settings[\.behavior].utilityMode.toggle()
            // Reset capture system when utility mode is toggled
            Task {
                // The notification will handle the alert state changes
                await ScreenRecorder.shared.resetAndStartCapture()
            }
        }) {
            if isHovered {
                Image(systemName: "hammer\(Settings[\.behavior].utilityMode ? ".fill" : "")")
                    .foregroundStyle(Color(nsColor: .labelColor))
            } else {
                Image(systemName: "hammer\(Settings[\.behavior].utilityMode ? ".fill" : "")")
            }
        }
        .popoverLabel("Utility Mode")
        .onHover { isHovered = $0 }
    }
}
