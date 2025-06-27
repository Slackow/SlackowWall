//
//  ToolbarStopView.swift
//  SlackowWall
//
//  Created by Kihron on 7/24/24.
//

import SwiftUI

struct ToolbarStopView: View {
    @ObservedObject private var instanceManager = InstanceManager.shared

    var body: some View {
        Button(action: { instanceManager.stopAll() }) {
            Image(systemName: "stop.fill")
                .foregroundColor(.red)
                .frame(width: 20, height: 20)
        }
        .disabled(instanceManager.isStopping)
        .popoverLabel("Stop All")
    }
}

#Preview {
    ToolbarStopView()
}
