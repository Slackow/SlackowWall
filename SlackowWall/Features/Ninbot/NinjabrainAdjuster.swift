//
//  NinjabrainAdjuster.swift
//  SlackowWall
//
//  Created by Andrew on 2/2/26.
//

import SwiftUI

struct NinjabrainAdjuster {

    struct Adjuster: Codable {
        var id: NinBotSetting
        var defaultValue: JavaValue?
        var adjustment: JavaValue
        var allowedError: Double?
    }

    enum JavaType: String, Codable {
        case boolean, int, double, float, string
    }

    enum JavaValue: Codable, Equatable, Hashable, CustomStringConvertible {
        case boolean(Bool)
        case int(Int32)
        case double(Float64)
        case float(Float32)
        case string(String)

        enum CodingKeys: String, CodingKey {
            case type, value
        }

        var description: String {
            switch self {
                case .boolean(let value):
                    return "\(value)"
                case .int(let value):
                    return "\(value)"
                case .double(let value):
                    return "\(value)"
                case .float(let value):
                    return "\(value)"
                case .string(let value):
                    return "\(value)"
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
                case .boolean(let value):
                    try container.encode("boolean", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .int(let value):
                    try container.encode("int", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .double(let value):
                    try container.encode("double", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .float(let value):
                    try container.encode("float", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .string(let value):
                    try container.encode("string", forKey: .type)
                    try container.encode(value, forKey: .value)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
                case "boolean":
                    let value = try container.decode(Bool.self, forKey: .value)
                    self = .boolean(value)

                case "int":
                    let value = try container.decode(Int32.self, forKey: .value)
                    self = .int(value)

                case "double":
                    let value = try container.decode(Float64.self, forKey: .value)
                    self = .double(value)

                case "float":
                    let value = try container.decode(Float32.self, forKey: .value)
                    self = .float(value)

                case "string":
                    let value = try container.decode(String.self, forKey: .value)
                    self = .string(value)

                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .type,
                        in: container,
                        debugDescription: "Unknown JavaValue type: \(type)"
                    )
            }
        }
    }

    struct Adjustments: Codable {
        var breaking: [Adjuster]
        var recommend: [Adjuster]
    }

    static var ninjabrainBotProc: Process? = nil

    @MainActor
    @discardableResult static func startIfClosed() -> Bool {
        if let ninjabrainBotProc, ninjabrainBotProc.isRunning {
            return false
        }

        if let ninjabrain = Settings[\.utility].ninjabrainBotLocation {
            guard !isJarAlreadyRunning(at: ninjabrain.path(percentEncoded: false)) else { return false }
            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/java")
            process.arguments = ["-jar", ninjabrain.path(percentEncoded: false)]
            do {
                try process.run()
            } catch {
                LogManager.shared.appendLog("Could not launch nin bot: ", error)
            }
            ninjabrainBotProc = process
        }
        return true
    }

    enum NinBotSetting: String, Codable {
        case sensitivity, sigma_boat, resolution_height, mc_version

        case alt_clipboard_reader, use_precise_angle, crosshair_correction
        case angle_adjustment_type, angle_adjustment_display_type

        case default_boat_type, hotkey_boat_code

        case show_angle_errors, mismeasure_warning_enabled, direction_help_enabled

        var name: String {
            switch self {
                case .sensitivity: "Sensitivity 1.13+ (BoatEye)"
                case .sigma_boat: "Standard deviation for boat throws"
                case .resolution_height: "Resolution height"
                case .mc_version: "Minecraft version"

                case .alt_clipboard_reader: "Use alternative clipboard reader"
                case .use_precise_angle: "Enable boat measurements"
                case .crosshair_correction: "Crosshair correction"
                case .angle_adjustment_type: "Pixel adjustment type"
                case .angle_adjustment_display_type: "Adjustment display type"
                case .default_boat_type: "Default boat mode"
                case .show_angle_errors: "Show angle errors"
                case .mismeasure_warning_enabled:
                    "Enables a warning when your error is too large for your standard deviation"
                case .direction_help_enabled:
                    "Show how far sideways you have to move to get >95% certainty"

                case .hotkey_boat_code: "N/A"
            }
        }

        func valueName(_ value: JavaValue) -> String {
            switch (self, value) {
                case (.mc_version, .int(0)): "1.9-1.18"
                case (.mc_version, .int(1)): "1.19+"
                case (.sigma_boat, .float(let val)): val.formatted(.number.precision(.fractionLength(0...4)))
                case (.angle_adjustment_type, .int(0)): "Subpixel (±0.01)"
                case (.angle_adjustment_type, .int(1)): "Tall resolution"
                case (.angle_adjustment_type, .int(2)): "Custom adjustment"
                case (.angle_adjustment_display_type, .int(0)): "Angle change"
                case (.angle_adjustment_display_type, .int(1)): "Number of adjustments"
                case (.default_boat_type, .int(0)): "Gray"
                case (.default_boat_type, .int(1)): "Blue"
                case (.default_boat_type, .int(2)): "Green"
                case (_, .boolean(true)): "On"
                case (_, .boolean(false)): "Off"
                case (_, .float(_)), (_, .double(_)):
                    value.description.hasSuffix(".0") ? String(value.description.dropLast(2)) : value.description
                default: value.description
            }
        }

        var description: String? {
            switch self {
                case .sensitivity:
                    "Your Ninjabrain bot sensitivity must be the same as in SlackowWall and Minecraft."
                case .sigma_boat:
                    "Your standard deviation, determines the confidence of your throws, and directly depends on your resolution height."
                case .resolution_height:
                    "The height of your window in tall mode, depends on your usage of retiNO mod, and what display you use."
                case .mc_version: "This setting has to match your instance's version"

                case .alt_clipboard_reader: "This should always be off, it doesn't work on macOS"
                case .use_precise_angle: "This enables BoatEye Measurements for NinjabrainBot"
                case .crosshair_correction:
                    "This should always be 0 when doing BoatEye, it adjusts your angle after measuring"
                case .angle_adjustment_type: "This should be set to 'Tall resolution'"
                case .angle_adjustment_display_type: "This should be set to 'Number of adjustments'"
                case .default_boat_type:
                    "This should generally be either blue or green, Green is recommended"

                case .show_angle_errors:
                    "Shows you the difference between your eye measurement and the true angle of the stronghold"
                case .mismeasure_warning_enabled: "Shows a warning for large angle errors"
                case .direction_help_enabled:
                    "Shows how far sideways you have to move to get >95% certainty"

                case .hotkey_boat_code: "N/A"
            }
        }
    }

    enum Action: String, Codable {
        case fixAll = "fix-all"
        case fixBreaking = "fix-breaking"
        case get = "get"
    }

    static func estimateSigmaFromResHeight(resHeight: Float32) -> Float32 {
        // Calculated from using curve of best fit on a graph, important points are 16384 -> 0.007, 8192 -> 0.0013
        0.0001405566 + (6877.937 - 0.0001305566)
            / pow((1 + pow(abs(resHeight) / 0.0532672, 0.158923)), 7.651672)
    }

    static func get(instance: TrackedInstance) throws -> Results {
        do {
            if let results = try act(instance: instance, action: .get) {
                return results
            } else {
                throw AdjustmentError.noResultError
            }
        } catch {
            LogManager.shared.appendLog("Ran into problem w/ adjusting NinBot: ", error)
            throw error
        }
    }

    static func fix(instance: TrackedInstance, action: Action = .fixAll, fixFilter: [NinBotSetting]? = nil) throws {
        do {
            try act(instance: instance, action: action, fixFilter: fixFilter)
            if fixFilter?.isEmpty != true {
                Task { @MainActor in
                    if TrackingManager.shared.killNinjabrainBot() != nil {
                        LogManager.shared.appendLog("Killed NinjabrainBot")
                        try? await Task.sleep(for: .seconds(2))
                        LogManager.shared.appendLog("Restarting NinjabrainBot")
                        NinjabrainAdjuster.startIfClosed()
                    } else {
                        LogManager.shared.appendLog("Ninjabrain Bot not open/not detected")
                    }
                }
            }
        } catch {
            LogManager.shared.appendLog("Ran into problem w/ adjusting NinBot: ", error)
            throw error
        }
    }

    static func isGodSens(_ sens: Double) -> Bool {
        [0.02291165, 0.058765005, 0.07446537].contains { abs($0 - sens) < 0.0000001 }
    }

    @discardableResult
    private static func act(
        instance: TrackedInstance, action: Action, fixFilter: [NinBotSetting]? = nil
    ) throws -> Results? {
        guard let prefReader = Bundle.main.url(forResource: "NinbotPrefReader-1.0", withExtension: "jar")
        else {
            throw AdjustmentError.toolNotFound
        }

        let sens = Settings[\.utility].boatEyeSensitivity
        let isGodSens = isGodSens(sens)
        let isLoDPI =
            (instance.hasMod(.retino))
            || NSScreen.factor == 1
        let resolutionHeight = Float32(
            Settings[\.self].tallDimensions(for: instance).1 * (isLoDPI ? 1 : 2))
        let sigmaBoat = estimateSigmaFromResHeight(resHeight: resolutionHeight)
        let mcVersion: Int32 = instance.info.majorVersion < 19 ? 0 : 1

        var dict = Adjustments(
            breaking: [
                Adjuster(id: .sensitivity, defaultValue: .double(0.012727597), adjustment: .double(sens)),
                Adjuster(
                    id: .sigma_boat, defaultValue: .float(0.001), adjustment: .float(sigmaBoat),
                    allowedError: 0.00025),
                Adjuster(id: .resolution_height, defaultValue: .float(16384.0), adjustment: .float(resolutionHeight)),
                Adjuster(id: .mc_version, adjustment: .int(mcVersion)),

                isGodSens
                    ? Adjuster(id: .default_boat_type, adjustment: .int(2), allowedError: 1)
                    : Adjuster(id: .default_boat_type, adjustment: .int(1)),

                Adjuster(id: .alt_clipboard_reader, adjustment: .boolean(false)),
                Adjuster(id: .use_precise_angle, adjustment: .boolean(true)),
                Adjuster(id: .crosshair_correction, adjustment: .double(0)),

                Adjuster(id: .angle_adjustment_type, adjustment: .int(1)),
                Adjuster(id: .angle_adjustment_display_type, adjustment: .int(1)),
            ],
            recommend: [
                Adjuster(id: .default_boat_type, adjustment: .int(isGodSens ? 2 : 1)),
                Adjuster(id: .show_angle_errors, adjustment: .boolean(true)),
                Adjuster(id: .mismeasure_warning_enabled, adjustment: .boolean(true)),
                Adjuster(id: .direction_help_enabled, adjustment: .boolean(true)),
            ]
        )
        if action == .get {
            // Hack to not suggest switching from gray boat if the hotkey is configured. Yeah I'm hacking around my own project, deal with it.
            dict.recommend.append(Adjuster(id: .hotkey_boat_code, defaultValue: .int(-1), adjustment: .int(-1)))
        }
        guard let adjustments = String(data: try JSONEncoder().encode(dict), encoding: .utf8) else {
            throw AdjustmentError.encodingError
        }

        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(filePath: "/usr/bin/java")
        proc.arguments = [
            "-jar",
            prefReader.path(percentEncoded: false),
            action.rawValue,
            adjustments,
        ]
        if let fixFilter {
            do {
                let data = try JSONEncoder().encode(fixFilter)
                guard let arg = String(data: data, encoding: .utf8) else {
                    throw AdjustmentError.encodingError
                }
                proc.arguments?.append(arg)
            } catch {
                throw AdjustmentError.encodingError
            }
        }
        proc.standardOutput = pipe
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            if !data.isEmpty {
                do {
                    var results = try JSONDecoder().decode(Results.self, from: data)
                    if let change = results.breaking.first(where: { $0.id == .default_boat_type }),
                        results.recommend.contains(where: { $0.id == .hotkey_boat_code })
                    {
                        results.recommend.append(change)
                        results.breaking.removeAll { $0.id == .default_boat_type }
                        results.recommend.removeAll { $0.id == .hotkey_boat_code }
                    }
                    return results
                } catch {
                    LogManager.shared.appendLog("Decoding: ", String(data: data, encoding: .utf8) ?? "")
                    throw AdjustmentError.decodingError
                }
            }
        } catch {
            throw AdjustmentError.executionError
        }
        return nil
    }

    struct Results: Codable {
        var breaking: [NinBotResult]
        var recommend: [NinBotResult]
    }

    struct NinBotResult: Codable, Equatable, Hashable {
        var id: NinBotSetting
        var oldValue: JavaValue
        var newValue: JavaValue
    }

    enum AdjustmentError: LocalizedError {
        case toolNotFound, encodingError, decodingError, executionError, noResultError
    }
}
