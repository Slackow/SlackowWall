//
//  StartupAppSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/24/25.
//

import SwiftUI

struct StartupAppSettings: View {
    
    @AppSettings(\.utility) var settings
    
    var body: some View {
        VStack {
            SettingsLabel(title: "Startup Applications", description: "Enable launching apps/jars automatically when starting SlackowWall (they will not close with it).")
            
            SettingsCardView {
                VStack {
                    SettingsToggleView(title: "Enabled", option: $settings.startupApplicationEnabled)
                    FileListView(urls: $settings.startupApplications)
                        .disabled(!settings.startupApplicationEnabled)
                }
            }
        }
    }
}

#Preview {
    StartupAppSettings()
}
