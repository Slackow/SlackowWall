//
//  UpdateMessageView.swift
//  SwiftAA
//
//  Created by Kihron on 3/7/24.
//

import SwiftUI

struct UpdateMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var updateManager = UpdateManager.shared

    var title: String

    private var appVersion: String {
        return updateManager.appVersion ?? ""
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title) • v\(appVersion)")
                .font(.title2)
                .fontWeight(.bold)

            SettingsCardView(padding: 0) {
                Group {
                    if !updateManager.releaseNotes.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(updateManager.releaseNotes) { entry in
                                    if entry.tagName.dropFirst() == appVersion {
                                        UpdateReleaseEntryView(
                                            title: "\(entry.tagName.dropFirst()) (Current)",
                                            releaseEntry: entry)
                                    } else {
                                        UpdateReleaseEntryView(releaseEntry: entry)
                                    }
                                }
                            }
                            .padding(.bottom)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        Text("There are no release notes available at this time.")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }

            Button(action: { dismiss() }) {
                Text("Close")
            }.frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 500, height: 300)
    }
}

#Preview {
    UpdateMessageView(title: "App Updated")
}
