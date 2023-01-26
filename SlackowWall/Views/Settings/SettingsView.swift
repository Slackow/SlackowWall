//
//  SettingsView.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @State private var stopped = false
    var body: some View {
        HStack {
            Form {
                HStack {
                    Text(stopped ? "Bye!" : "Stop Instances: ")
                    Button (action: { [self] in
                        stopped = true
                        ShortcutManager.shared.killAll()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            exit(0)
                        }
                    }) {
                        Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                    }
                            .disabled(stopped)
                }

            }.padding(10)
            SettingsCardView(title: "Keybinds") {
                Form {
                    KeyboardShortcuts.Recorder("Reset:", name: .reset)
                    KeyboardShortcuts.Recorder("Widen Instance:", name: .planar)
                    Button("Reset To Defaults") {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                        UserDefaults.standard.synchronize()
                    }
                }
                .padding()
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
