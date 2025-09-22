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
    @ObservedObject private var trackingManager = TrackingManager.shared

    @State private var showTokenAlert = false
    @State var tokenResponse: TokenResponse?

    @State var tallSensitivityFactor: Double = Settings[\.utility].tallSensitivityFactor
    @State var boatEyeSensitivity: Double = Settings[\.utility].boatEyeSensitivity

    var usingRetino: Bool {
        trackingManager.trackedInstances.first {
            $0.info.mods.contains { $0.id == "retino" }
        } != nil
    }
    static let mouseSensTextRegex = /^mouseSensitivity:([\d.]+)$/.anchorsMatchLineEndings()
    @State var wrongSensitivities: [TrackedInstance]? = nil
    func getWrongSensitivities() -> [TrackedInstance]? {
        if trackingManager.trackedInstances.isEmpty {
            return nil
        }
        return trackingManager.trackedInstances.filter { instance in
            guard let data = FileManager.default.contents(atPath: "\(instance.info.path)/options.txt"),
                let file = String(data: data, encoding: .utf8),
                  let match = (try? UtilitySettings.mouseSensTextRegex.firstMatch(in: file))?.output.1,
                let sens = Double(match)
             else {
                return false
            }
            // TODO: can't get sensitivity, what do I do?
            return abs(sens - boatEyeSensitivity) > 0.00001
        }
    }

    @FocusState var sensFieldInFocus
    @State var sensFieldNum: Double? = nil

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
                            .controlSize(.small)
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
                    """
            )

            SettingsCardView {
                VStack {
                    SettingsToggleView(title: "Enabled", option: $settings.sensitivityScaleEnabled)
                    Divider()
                    SettingsToggleView(
                        title: "Toolbar Icon", option: $settings.sensitivityScaleToolBarIcon)
                    Divider()
                    Group {
                        HStack {
                            SettingsLabel(title: "Simulated Sensitivity", font: .body)
                            Text(sensitivityText(scaleToSens(scale: settings.sensitivityScale)+0.001))
                            .opacity(sensFieldInFocus ? 0.2 : 1)
                            .foregroundStyle(Color(nsColor: settings.sensitivityScaleEnabled ? .labelColor : .tertiaryLabelColor))
                            .overlay {
                                    TextField(
                                        "", value: .init {sensFieldNum} set: { (n: Double?) in
                                            sensFieldNum = n
                                            if var n {
                                                if n < 1 { n *= 200 }
                                                settings.sensitivityScale = sensToScale(mcUnits: n)
                                                MouseSensitivityManager.shared.setSensitivityFactor(
                                                    factor: settings.sensitivityScale)
                                            }
                                        },
                                        format: .number.grouping(.never)
                                    )
                                    .textFieldStyle(.plain)
                                    .focused($sensFieldInFocus)
                                    .onChange(of: sensFieldInFocus) { _, newValue in
                                        if !newValue {
                                            sensFieldNum = nil
                                        }
                                    }
                                    .onSubmit {
                                        sensFieldNum = nil
                                        sensFieldInFocus = false
                                    }
                            }
                            Slider(value: .init(get: {scaleToSens(scale: settings.sensitivityScale)}, set: {
                                settings.sensitivityScale = sensToScale(mcUnits: $0)
                            }), in: 0...200, onEditingChanged: { _ in
                                MouseSensitivityManager.shared.setSensitivityFactor(
                                    factor: settings.sensitivityScale)
                            })
                            .frame(width: 200)
                            .frame(minHeight: 20)
                        }
                        Divider()

                        HStack {
                            SettingsLabel(title: "BoatEye Sensitivity", font: .body)
                            Button(action: fixSensitivities) {
                                if let wrongSensitivities, !wrongSensitivities.isEmpty {
                                    let labels = wrongSensitivities.map{"\"\($0.name)\""}.joined(separator: ", ")
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(.red)
                                        .popoverLabel("Instance(s) \(labels) are not using your BoatEye Sensitivity,\nWith this option enabled, this may cause mouse jittering\nClick to change the sensitivity (they will close)")
                                } else {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(.green)
                                        .popoverLabel("Your instance(s) are using your BoatEye sensitivity")
                                }
                            }.buttonStyle(.plain)
                                .opacity(settings.sensitivityScaleEnabled && wrongSensitivities != nil ? 1 : 0)
                                .onChange(of: settings.sensitivityScaleEnabled, { _, newValue in
                                    if newValue {
                                        wrongSensitivities = getWrongSensitivities()
                                    }
                                 })
                                .onChange(of: trackingManager.trackedInstances, {
                                    wrongSensitivities = getWrongSensitivities()
                                })
                                 .onAppear {
                                    if settings.sensitivityScaleEnabled {
                                        wrongSensitivities = getWrongSensitivities()
                                    }
                                 }
                            TextField(
                                "", value: .init(get: {
                                    settings.boatEyeSensitivity
                                }, set: {
                                    settings.boatEyeSensitivity = $0

                                    MouseSensitivityManager.shared.setSensitivityFactor(
                                        factor: settings.sensitivityScale)
                                }),
                                format: .number.grouping(.never).precision(.fractionLength(0...10))
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100, alignment: .trailing)
                            .overlay {
                                Button("", systemImage: "xmark.circle.fill") {
                                    settings.boatEyeSensitivity = 0.02291165
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .offset(x: 5, y: -1.5)
                                .disabled(settings.boatEyeSensitivity == 0.02291165)
                            }
                        }

                        Divider()
                    }.disabled(!settings.sensitivityScaleEnabled)
                    HStack {
                        SettingsLabel(title: "Tall Mode Sensitivity Scale", description: """
                            Lower sensitivity by \(settings.tallSensitivityFactor)x while in tall mode
                            """, font: .body)
                        .contentTransition(.numericText())
                        .animation(.smooth, value: tallSensitivityFactor)
                        Toggle("", isOn: $settings.tallSensitivityFactorEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                        TextField(
                            "", value: $tallSensitivityFactor,
                            format: .number.grouping(.never)
                        )
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor((0.05...100 ~= tallSensitivityFactor) ? .primary : .red)
                        .frame(width: 100)
                        .onChange(of: tallSensitivityFactor) { _, newValue in
                            Settings[\.utility].tallSensitivityFactor = (0.05...100).clamped(value: newValue)
                        }
                        .disabled(!settings.tallSensitivityFactorEnabled)
                    }
                }
            }

            SettingsLabel(
                title: "Paceman Tracker",
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

    private func sensitivityText(_ sens: Double) -> String {
        switch sens {
            case 0...0.001:
                return "*yawn*"
            case 200...200.001:
                return "HYPERSPEED!!!"
            default:
                return "\(Int(sens))%"
        }
    }

    private func fractionToLinear(_ s: Double) -> Double {
        8 * pow(0.6 * s + 0.2, 3)
    }

    private func linearToFraction(_ linear: Double) -> Double {
        (cbrt(linear / 8.0) - 0.2) / 0.6
    }

    private func uiToFraction(_ units: Double) -> Double { units / 200.0 }
    private func fractionToUI(_ frac: Double) -> Double { min(max(frac, 0), 1) * 200.0 }

    private func sensToScale(mcUnits: Double) -> Double {
        let sNew = uiToFraction(mcUnits)
        let sBase = settings.boatEyeSensitivity
        return fractionToLinear(sNew) / fractionToLinear(sBase)
    }

    private func scaleToSens(scale: Double) -> Double {
        let baseLinear = fractionToLinear(settings.boatEyeSensitivity)
        let newLinear  = baseLinear * scale
        let sNew       = linearToFraction(newLinear)
        return fractionToUI(sNew)
    }

    private func fixSensitivities() {
        guard let wrongSensitivities, !wrongSensitivities.isEmpty else { return }
        self.wrongSensitivities = nil
        let fm = FileManager.default
        for inst in wrongSensitivities {
            let path = inst.info.path
            let optionsPath = "\(path)/options.txt"
            let standardSettingsTxt = "\(path)/config/standardoptions.txt"
            let standardSettingsJson = "\(path)/config/mcsr/standardsettings.json"
            let hasStandardSettings = inst.info.mods.map(\.id).contains("standardsettings")
            if hasStandardSettings && !(fm.fileExists(atPath: standardSettingsJson) || fm.fileExists(atPath: standardSettingsTxt)) {
                LogManager.shared.appendLog("Cannot figure out how to fix standard settings \(inst.name), skipping.")
                continue
            }
            trackingManager.kill(instance: inst)
            do {
                let contents = try String(contentsOfFile: optionsPath, encoding: .utf8)
                let replacement = contents.replacing(UtilitySettings.mouseSensTextRegex) { _ in
                    "mouseSensitivity:\(boatEyeSensitivity)"
                }
                try replacement.write(to: URL(filePath: optionsPath), atomically: true, encoding: .utf8)
                LogManager.shared.appendLog("Wrote \(boatEyeSensitivity) to options.txt \(inst.name)")
            } catch {
                LogManager.shared.appendLog("Failed to write to options.txt \(inst.name), skipping.")
            }
            if hasStandardSettings {
                do {
                    let rootStandardSettingsTxt = followStandardSettingsTxt(path: URL(filePath: standardSettingsTxt))
                    let contents = try String(contentsOf: rootStandardSettingsTxt, encoding: .utf8)
                    let replacement = contents.replacing(UtilitySettings.mouseSensTextRegex) { _ in
                        "mouseSensitivity:\(boatEyeSensitivity)"
                    }
                    try replacement.write(to: URL(filePath: standardSettingsTxt), atomically: true, encoding: .utf8)
                    LogManager.shared.appendLog("Wrote \(boatEyeSensitivity) to standardoptions.txt \(inst.name)")
                } catch {
                    LogManager.shared.appendLog("Failed to write to standardoptions.txt \(inst.name), skipping.")
                }
                do {
                    // TODO: The logic for JSON file
                    let contents = try Data(contentsOf: URL(filePath:standardSettingsJson))
                    let json = (try JSONSerialization.jsonObject(with: contents, options: [])) as? [String:Any]
                    guard var json else {
                        LogManager.shared.appendLog("Failed to read to standardsettings.json \(inst.name), skipping.")
                        continue
                    }
                    json["mouseSensitivity"] = ["value": boatEyeSensitivity, "enabled": true]
                    let replacement = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                    try replacement.write(to: URL(filePath: standardSettingsJson))
                    LogManager.shared.appendLog("Wrote \(boatEyeSensitivity) to standardsettings.json \(inst.name)")
                } catch {
                    LogManager.shared.appendLog("Failed to write to standardsettings.json \(inst.name), skipping.")
                }
            }

        }
    }

    private func followStandardSettingsTxt(path: URL) -> URL {
        if let content = (try? String(contentsOf: path, encoding: .utf8))?.components(separatedBy: "\n").first,
            FileManager.default.fileExists(atPath: content)
        {
            followStandardSettingsTxt(path: URL(filePath: content))
        } else {
            path
        }
    }
}

#Preview {
    ScrollView {
        UtilitySettings()
            .padding()
    }
}

