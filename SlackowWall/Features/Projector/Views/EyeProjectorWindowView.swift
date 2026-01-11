//
//  EyeProjectorWindowView.swift
//  SlackowWall
//
//  Created by Andrew on 5/31/25.
//

import SwiftUI

struct EyeProjectorWindowView: View {

    @ObservedObject
    var screenRecorder = ScreenRecorder.shared
    @ObservedObject
    var shortcutManager = ShortcutManager.shared

    @AppSettings(\.utility) var settings
    var body: some View {
        if !settings.eyeProjectorEnabled {
            Text("Projector is disabled")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if shortcutManager.eyeProjectorOpen,
                  let instance = screenRecorder.eyeProjectedInstance {
            EyeProjectorView(instance: instance)
        } else {
            Text("No Tall Instance to Project")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    EyeProjectorWindowView()
}
