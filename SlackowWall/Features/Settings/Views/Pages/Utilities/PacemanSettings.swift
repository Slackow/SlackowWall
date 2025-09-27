//
//  PacemanSettings.swift
//  SlackowWall
//
//  Created by Andrew on 9/24/25.
//

import SwiftUI

struct PacemanSettings: View {
    
    @AppSettings(\.utility) var settings
    @ObservedObject var pacemanManager = PacemanManager.shared
    @Environment(\.openURL) var openURL
    
    @State private var showTokenAlert = false
    @State var tokenResponse: TokenResponse?
    
    var body: some View {
            SettingsLabel(
                title: "Paceman Tracker",
                description: """
        Configure Settings for Paceman, a site that tracks your live statistics and/or \
        reset statistics.
        View statistics, and generate token here: [paceman.gg](https://paceman.gg)
        SpeedrunIGT 14.2+ is required.
        """
            )
            
            SettingsCardView {
                VStack {
                    SettingsToggleView(
                        title: "Auto-launch Paceman",
                        description: "Automatically launch Paceman with SlackowWall.",
                        option: $settings.autoLaunchPaceman)
                    Divider()
                    SettingsToggleView(title: "Toolbar Icon", option: $settings.pacemanToolBarIcon)
                    
                    Divider()
                    SettingsLabel(
                        title: "Paceman Tracker Settings",
                        description:
                            "These settings are directly tied to the Paceman tracker.",
                        font: .body
                    )
                    SettingsCardView {
                        VStack {
                            HStack {
                                Text("Paceman Token")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button("Test") {
                                    Task(priority: .userInitiated) {
                                        await validateToken()
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
                                    description: "Paceman will close with SlackowWall.", font: .body
                                )
                                
                                Button {
                                    if pacemanManager.isRunning {
                                        pacemanManager.stopPaceman()
                                    } else {
                                        pacemanManager.startPaceman()
                                    }
                                } label: {
                                    HStack {
                                        Image(
                                            systemName: pacemanManager.isRunning
                                            ? "stop.fill" : "play.fill"
                                        )
                                        .foregroundStyle(pacemanManager.isRunning ? .red : .green)
                                        Text(
                                            pacemanManager.isRunning
                                            ? "Stop Paceman" : "Start Paceman")
                                    }
                                }
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
                        Text("Token is valid for \(name)!")
                    case .invalid:
                        Text("Invalid token, check it was input correctly.")
                    case .unable:
                        Text("Error checking token, please try again later.")
                }
            }
        
    }
    
    

    private func validateToken() async {
        let token = pacemanManager.pacemanConfig.accessKey
        if token.isEmpty {
            tokenResponse = .empty
        } else {
            do {
                if let name = try await PacemanManager.validateToken(token: token) {
                    tokenResponse = .valid(name)
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
}

#Preview {
    PacemanSettings()
}
