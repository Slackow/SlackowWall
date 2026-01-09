//
//  PieProjectorWindowView.swift
//  SlackowWall
//
//  Created by Andrew on 1/7/26.
//

import SwiftUI

struct PieProjectorWindowView: View {
    @ObservedObject
    var screenRecorder = ScreenRecorder.shared

    @AppSettings(\.utility) var settings
    var body: some View {
        if !settings.pieProjectorEnabled {
            Text("Pie Projector is disabled")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let instance = screenRecorder.eyeProjectedInstance {
            EyeProjectorView(instance: instance)
        } else {
            Text("No Instance to Project")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    PieProjectorWindowView()
}
