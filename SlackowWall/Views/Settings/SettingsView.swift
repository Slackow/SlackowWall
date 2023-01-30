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

    @AppStorage("rows") var rows: Int = AppDefaults.rows
    @AppStorage("alignment") var alignment: Alignment = AppDefaults.alignment

    var body: some View {
        HStack(spacing: 10) {
            SettingsCardView(title: "Configuration") {
                Form {
                    VStack(alignment: .leading) {
                        VStack {
                            HStack {
                                Text("Direction")

                                Picker("", selection: $alignment) {
                                    ForEach(Alignment.allCases, id: \.self) { type in
                                        Text(type == .vertical ? "Columns" : "Rows").tag(type)
                                    }
                                }.pickerStyle(.segmented)
                            }

                            Picker("", selection: $rows) {
                                ForEach(1..<10) {
                                    Text("\($0)").tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        HStack {
                            Text(stopped ? "Bye!" : "Stop Instances: ")

                            Button(action: { [self] in
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
                    }
                }
                .padding()
            }
            .padding(.vertical, 10)
            .frame(maxHeight: .infinity, alignment: .topLeading)

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
            .padding(.vertical, 10)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
