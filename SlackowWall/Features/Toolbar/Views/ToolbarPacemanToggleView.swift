//
//  ToolbarSensitivityToggleView.swift
//  SlackowWall
//
//  Created by Andrew on 6/4/25.
//

import SwiftUI

struct ToolbarPacemanToggleView: View {
    @ObservedObject private var paceman = PacemanManager.shared

    @State private var isHovered: Bool = false
    @AppSettings(\.utility)
    private var settings

    var body: some View {
        Button(action: {
            if paceman.isRunning {
                paceman.stopPaceman()
            } else {
                paceman.startPaceman()
            }
        }) {
            (!paceman.isRunning
                ? Image("figure.slowrun")
                : paceman.isShuttingDown
                    ? Image(systemName: "figure.stand") : Image("figure.paceman.fill"))
                .symbolRenderingMode(.multicolor)
                .resizable()
                .aspectRatio(
                    contentMode: paceman.isRunning && !paceman.isShuttingDown ? .fill : .fit
                )

        }
        .foregroundStyle(Color(nsColor: isHovered ? .labelColor : .secondaryLabelColor))
        .popoverLabel((paceman.isRunning ? "Stop" : "Start") + " Paceman")
        .onHover { isHovered = $0 }
    }
}
#Preview {
    ToolbarSensitivityToggleView()
}
