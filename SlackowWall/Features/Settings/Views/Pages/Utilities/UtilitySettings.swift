//
//  UtilitySettings.swift
//  SlackowWall
//
//  Created by Andrew on 5/26/25.
//

import SwiftUI

struct UtilitySettings: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow

    @AppSettings(\.utility) private var settings
    @AppSettings(\.keybinds) private var keybinds

    @ObservedObject private var pacemanManager = PacemanManager.shared

    @State private var showTokenAlert = false
    @State var tokenResponse: TokenResponse?

    @State var sensitivityScale: Double = Settings[\.utility].sensitivityScale
    @State var tallSensitivityScale: Double = Settings[\.utility].tallSensitivityScale

    var usingRetino: Bool {
        TrackingManager.shared.trackedInstances.first {
            $0.info.mods.contains { $0.id == "retino" }
        } != nil
    }

    var body: some View {
        SettingsPageView(title: "Utilities", shouldDisableFocus: true) {
            SettingsLabel(
                title: "Eye Projector",
                description: """
                    Settings for an automated eye projector for BoatEye.
                    """)

            SettingsCardView {
                VStack {
                    HStack {
                        SettingsLabel(title: "Enabled", font: .body)

                        Button("Open") {
                            openWindow(id: "eye-projector-window")
                        }
                        .disabled(!settings.eyeProjectorEnabled)

                        Toggle("", isOn: $settings.eyeProjectorEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(.accentColor)
                    }

                    Group {
                        Divider()

                        SettingsToggleView(
                            title: "Open/Close With Tall Mode",
                            option: $settings.eyeProjectorOpenWithTallMode
                        )

                        Divider()

                        SettingsToggleView(
                            title: "Adjust For No Retino Mod",
                            description: usingRetino && settings.adjustFor4kScaling
                                ? """
                                [You are using Retino, turn this off](0)
                                """
                                : """
                                Enable this if you are using a 4K or Retina screen, \
                                without the Retino mod.
                                """,
                            descInteractable: false,
                            option: $settings.adjustFor4kScaling,
                        )
                        .tint(.red)
                        .animation(.easeInOut, value: settings.adjustFor4kScaling)

                        Divider()

                        HStack {
                            SettingsLabel(
                                title: "Height Scale",
                                description: """
                                    Adjusts the "Stretch" on the y axis, \
                                    you probably want the default (0.2)
                                    """,
                                font: .body
                            )

                            SettingsInfoIcon(
                                description: """
                                    The Height Scale option determines how "squished" the eye is
                                    on the projector, a lower value gives you more leeway on how
                                    far above or below your cursor can be from the eye to still
                                    see it, and a higher number makes it easier to see the divide
                                    between the two important pixels, the ideal value depends on
                                    how tall you make the eye projector window, but generally it's
                                    recommended to keep it between 0.2-0.4, you can experiment
                                    with it with the window open to see what works best.
                                    """)

                            TextField(
                                "", value: $settings.eyeProjectorHeightScale,
                                format: .number.grouping(.never)
                            )
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(.primary)
                            .frame(width: 60)
                            .disabled(!settings.eyeProjectorEnabled)
                        }
                    }
                }
            }

            SettingsLabel(
                title: "Sensitivity Scaling",
                description: """
                    Allows your sensitivity to change when in tall mode, and to use lower \
                    sensitivities without affecting your unlocked cursor movements, this is used \
                    for BoatEye.
                    Go [here](https://slackow.github.io/ScaleFactorCalc/calc.html) to find the \
                    correct values for your sensitivity
                    """
            )

            SettingsCardView {
                VStack {
                    SettingsToggleView(title: "Enabled", option: $settings.sensitivityScaleEnabled)
                    Divider()
                    SettingsToggleView(
                        title: "Toolbar Icon", option: $settings.sensitivityScaleToolBarIcon)
                    Group {
                        Divider()

                        HStack {
                            SettingsLabel(title: "Sensitivity Scale", font: .body)

                            TextField(
                                "", value: $sensitivityScale,
                                format: .number.grouping(.never)
                            )
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor((0.05...50 ~= sensitivityScale) ? .primary : .red)
                            .frame(width: 60)
                            .onChange(of: sensitivityScale) { _, newValue in
                                if 0.05...50 ~= newValue {
                                    Settings[\.utility].sensitivityScale = newValue
                                    MouseSensitivityManager.shared.setSensitivityFactor(
                                        factor: newValue)
                                }
                            }
                        }

                        Divider()

                        HStack {
                            SettingsLabel(title: "Tall Mode Sensitivity Scale", font: .body)

                            TextField(
                                "", value: $tallSensitivityScale,
                                format: .number.grouping(.never)
                            )
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor((0.05...50 ~= tallSensitivityScale) ? .primary : .red)
                            .frame(width: 60)
                            .onChange(of: tallSensitivityScale) { _, newValue in
                                if 0.05...50 ~= newValue {
                                    Settings[\.utility].tallSensitivityScale = newValue
                                }
                            }
                        }
                    }.disabled(!settings.sensitivityScaleEnabled)
                }
            }

            SettingsLabel(
                title: "Paceman",
                description: """
                    Configure Settings for Paceman, a site that tracks your live statistics and/or \
                    reset statistics.
                    View statistics, and generate token here: [paceman.gg](https://paceman.gg)
                    SpeedrunIGT 14.2+ is required.
                    """
            )
            .padding(.bottom, -6)

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
    ScrollView {
        UtilitySettings()
            .padding()
    }
}
