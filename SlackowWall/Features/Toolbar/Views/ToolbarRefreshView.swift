//
//  ToolbarRefreshView.swift
//  SlackowWall
//
//  Created by Kihron on 7/24/24.
//

import SwiftUI

struct ToolbarRefreshView: View {
    @ObservedObject private var alertManager = AlertManager.shared
    @State private var isHovered: Bool = false
    var body: some View {
        Button(
            "", systemImage: "arrow.clockwise",
            action: {
                Task {
                    alertManager.checkPermissions()
                    GridManager.shared.showInfo = false
                    await ScreenRecorder.shared.resetAndStartCapture()
                }
            }
        ).onHover { isHovered = $0 }
            .foregroundStyle(Color(nsColor: isHovered ? .labelColor : .secondaryLabelColor))
            .popoverLabel("Refresh")
    }
}

#Preview {
    ToolbarRefreshView()
}
