//
//  UpdateSettings.swift
//  SwiftAA
//
//  Created by Kihron on 9/7/23.
//

import SwiftUI

struct UpdateSettings: View {
    @ObservedObject private var updateManager = UpdateManager.shared
    @State private var showReleaseNotes: Bool = false

    private var appInformation: String {
        return "SlackowWall \(updateManager.appVersion ?? "") (\(updateManager.appBuild ?? ""))"
    }

    var body: some View {
        VStack {
            SettingsCardView {
                VStack {
                    SettingsToggleView(
                        title: "Check Automatically", option: $updateManager.checkAutomatically)

                    Divider()

                    SettingsToggleView(
                        title: "Download Automatically",
                        option: $updateManager.downloadAutomatically
                    )
                    .disabled(!updateManager.checkAutomatically)
                }
            }

            VStack {
                Text(appInformation)

                if let lastUpdateCheck = updateManager.getLastUpdateCheckDate() {
                    HStack(spacing: 0) {
                        Text("Last Checked: ")

                        Text(lastUpdateCheck, formatter: updateManager.lastUpdateFormatter)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding([.horizontal, .top])
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Updates")
        .onChange(of: updateManager.checkAutomatically) { value in
            updateManager.automaticallyCheckForUpdates = value
        }
        .onChange(of: updateManager.downloadAutomatically) { value in
            updateManager.automaticallyDownloadUpdates = value
        }
        .sheet(isPresented: $showReleaseNotes) {
            UpdateMessageView(title: "Release Notes")
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showReleaseNotes.toggle() }) {
                    Image(systemName: "doc.plaintext")
                }
                .help("Show release notes")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: { updateManager.checkForUpdates() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Check for updates")
            }
        }
    }
}

#Preview {
    UpdateSettings()
        .frame(width: 500, height: 600)
}
