//
//  UtilitySettings.swift
//  SlackowWall
//
//  Created by Andrew on 5/26/25.
//

import CachedAsyncImage
import SwiftUI

struct UtilitySettings: View {

    @Environment(\.openURL) private var openURL

    @AppSettings(\.utility) private var settings
    @AppSettings(\.keybinds) private var keybinds

    @ObservedObject private var pacemanManager = PacemanManager.shared

    @State private var showTokenAlert = false
    @State var tokenResponse: TokenResponse?

    var body: some View {
        SettingsPageView(title: "Utilities", shouldDisableFocus: false) {
            SettingsLabel(
                title: "Paceman",
                description: """
                    Configure Settings for Paceman, a site that tracks your live statistics and/or \
                    reset statistics.
                    View statistics, and generate token here: [paceman.gg](https://paceman.gg)
                    """
            )
            .padding(.bottom, -6)
            SettingsCardView {
                SettingsToggleView(
                    title: "Auto-launch Paceman",
                    description: "Automatically launch Paceman with SlackowWall.",
                    option: $settings.autoLaunchPaceman)
            }
            SettingsLabel(
                title: "Paceman Tracker",
                description:
                    "These settings are directly tied to the Paceman tracker, and require it to be restarted in order to take effect."
            )
            SettingsCardView {
                VStack {
                    HStack {
                        Text("Paceman Token")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Test") {
                            Task {
                                await testToken()
                            }
                        }
                        SecureField(
                            "", text: $pacemanManager.pacemanConfig.accessKey,
                            onCommit: {
                                pacemanManager.pacemanConfig.accessKey = pacemanManager
                                    .pacemanConfig.accessKey.trimmingCharacters(
                                        in: .whitespacesAndNewlines)
                            }
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .disabled(pacemanManager.isRunning)
                    }
                    Divider()
                    SettingsToggleView(
                        title: "Track Reset Statistics",
                        option: $pacemanManager.pacemanConfig.resetStatsEnabled
                    )
                    .disabled(pacemanManager.isRunning)
                    Divider()
                    HStack {
                        SettingsLabel(
                            title: "Start/Stop Paceman",
                            description: "Paceman will close with SlackowWall.", font: .body)
                        Button {
                            if pacemanManager.isRunning {
                                pacemanManager.stopPaceman()
                            } else {
                                pacemanManager.startPaceman()
                            }
                        } label: {
                            HStack {
                                Image(
                                    systemName: pacemanManager.isRunning ? "stop.fill" : "play.fill"
                                )
                                .foregroundStyle(pacemanManager.isRunning ? .red : .green)
                                Text(pacemanManager.isRunning ? "Stop Paceman" : "Start Paceman")
                            }
                        }
                    }
                }
            }
            .alert(
                "Paceman Token",
                isPresented: $showTokenAlert,
                presenting: tokenResponse
            ) { response in
                switch response {
                    case .empty, .invalid:
                        Button("Get Token") {
                            if let url = URL(string: "https://paceman.gg") {
                                openURL(url)
                            }
                        }
                        Button("Close", role: .cancel) {}
                    case .valid, .unable:
                        Button("Ok") {}
                }
            } message: { response in
                switch response {
                    case .empty:
                        Text("No token found, generate here: paceman.gg")
                    case .valid(let name):
                        CachedAsyncImage(url: getAvatarURL(name))
                        Text("Token is Valid!")
                    case .invalid:
                        Text("Invalid token, check it was input correctly.")
                    case .unable:
                        Text("Error checking token, please try again later.")
                }
            }
        }
    }

    func testToken() async {
        let token = pacemanManager.pacemanConfig.accessKey
        if token.isEmpty {
            tokenResponse = .empty
        } else {
            do {
                if let uuid = try await PacemanManager.testToken(token: token) {
                    tokenResponse = .valid(uuid)
                } else {
                    tokenResponse = .invalid
                }
            } catch {
                LogManager.shared.appendLog("Error validating token:", error)
                tokenResponse = .unable
            }
        }
        showTokenAlert = true
    }

    enum TokenResponse {
        case valid(String)
        case invalid, empty, unable
    }

    private func getAvatarURL(_ uuid: String) -> URL? {
        return URL(string: "https://minotar.net/helm/\(uuid)/32")
    }
}

#Preview {
    ScrollView {
        UtilitySettings()
            .padding()
    }
}
