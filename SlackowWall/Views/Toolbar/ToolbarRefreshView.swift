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
        Button(action: { Task {
            alertManager.checkPermissions()
            GridManager.shared.showInfo = false
            await ScreenRecorder.shared.resetAndStartCapture()
        }}) {
            if isHovered {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(Color(nsColor: .labelColor))
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }.onHover {isHovered = $0}
    }
}

#Preview {
    ToolbarRefreshView()
}
