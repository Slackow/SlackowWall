//
//  ToolbarSensitivityToggleView.swift
//  SlackowWall
//
//  Created by Andrew on 6/4/25.
//

import SwiftUI

struct ToolbarSensitivityToggleView: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared

    @State private var isHovered: Bool = false
    @AppSettings(\.utility)
    private var settings

    var body: some View {
        Button(action: {
            settings.sensitivityScaleEnabled.toggle()
        }) {
            Image(systemName: "computermouse\(settings.sensitivityScaleEnabled ? ".fill" : "")")
                .foregroundStyle(Color(nsColor: isHovered ? .labelColor : .secondaryLabelColor))
                .frame(width: 18, height: 25)
        }
        .popoverLabel("Sensitivity Scaling")
        .onHover { isHovered = $0 }
        .onChange(of: settings.sensitivityScaleEnabled) { _, newValue in
            LogManager.shared.appendLog(
                "Sensitivity Scale", newValue ? "Enabled" : "Disabled")
            if newValue {
                let scale = settings.sensitivityScale
                DispatchQueue.main.async {
                    MouseSensitivityManager.shared.setSensitivityFactor(factor: scale)
                }
            } else {
                DispatchQueue.main.async {
                    MouseSensitivityManager.shared.stopReducingSensitivity()
                }
            }
        }
    }
}
#Preview {
    ToolbarSensitivityToggleView()
}
