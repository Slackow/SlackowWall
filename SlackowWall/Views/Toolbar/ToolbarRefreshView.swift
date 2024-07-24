//
//  ToolbarRefreshView.swift
//  SlackowWall
//
//  Created by Kihron on 7/24/24.
//

import SwiftUI

struct ToolbarRefreshView: View {
    @ObservedObject private var alertManager = AlertManager.shared
    
    var body: some View {
        Button(action: { Task {
            alertManager.checkPermissions()
            GridManager.shared.showInfo = false
            await ScreenRecorder.shared.resetAndStartCapture()
        }}) {
            Image(systemName: "arrow.clockwise")
        }
    }
}

#Preview {
    ToolbarRefreshView()
}
