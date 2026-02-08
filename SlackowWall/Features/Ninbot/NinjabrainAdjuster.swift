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

    enum JavaValue: Codable {
        case boolean(Bool)
        case int(Int32)
        case double(Float64)
        case float(Float32)
        case string(String)

        enum CodingKeys: String, CodingKey {
            case type, value
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

    enum NinBotSetting: String, Codable {
        case sensitivity, sigma_boat, resolution_height, mc_version

        case alt_clipboard_reader, use_precise_angle, crosshair_correction
        case angle_adjustment_type, angle_adjustment_display_type

        case default_boat_type

        case show_angle_errors, mismeasure_warning_enabled, direction_help_enabled
    }

    enum Action: String, Codable {
        case fixAll = "fix-all"
        case fixBreaking = "fix-breaking"
        case get = "get"
    }

    static func estimateSigmaFromResHeight(resHeight: Float32) -> Float32 {
        // Calculated from using curve of best fit on a graph, important points are 16384 -> 0.007, 8192 -> 0.0013
        0.0001485566 + (6877.937 - 0.0001485566)
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

    static func fix(instance: TrackedInstance, fixFilter: [NinBotSetting]? = nil) throws {
        do {
            try act(instance: instance, action: .fixAll, fixFilter: fixFilter)
            if fixFilter?.isEmpty != true {
                if TrackingManager.shared.killNinjabrainBot() != nil {
                    LogManager.shared.appendLog("Killed NinjabrainBot")
                } else {
                    LogManager.shared.appendLog("Ninjabrain Bot not open/not detected")
                }
            }
        } catch {
            LogManager.shared.appendLog("Ran into problem w/ adjusting NinBot: ", error)
            throw error
        }
    }

    @discardableResult
    private static func act(
        instance: TrackedInstance, action: Action, fixFilter: [NinBotSetting]? = nil
    ) throws -> Results? {
        guard
            let prefReader = Bundle.main.url(
                forResource: "NinbotPrefReader-1.0", withExtension: "jar")
        else {
            throw AdjustmentError.toolNotFound
        }

        let sens = Settings[\.utility].boatEyeSensitivity
        let isLoDPI =
            (instance.info.mods.map(\.id).contains("retino"))
            || NSScreen.primary?.backingScaleFactor == 1
        let resolutionHeight = Float32(
            Settings[\.self].tallDimensions(for: instance).1 * (isLoDPI ? 1 : 2))
        let sigmaBoat = estimateSigmaFromResHeight(resHeight: resolutionHeight)
        let mcVersion: Int32 = instance.info.majorVersion < 19 ? 0 : 1

        let dict = Adjustments(
            breaking: [
                Adjuster(
                    id: .sensitivity, defaultValue: .double(0.012727597), adjustment: .double(sens)),
                Adjuster(
                    id: .sigma_boat, defaultValue: .float(0.001), adjustment: .float(sigmaBoat),
                    allowedError: 0.00025),
                Adjuster(
                    id: .resolution_height, defaultValue: .float(16384.0),
                    adjustment: .float(resolutionHeight)),
                Adjuster(id: .mc_version, adjustment: .int(mcVersion)),

                Adjuster(id: .alt_clipboard_reader, adjustment: .boolean(false)),
                Adjuster(id: .use_precise_angle, adjustment: .boolean(true)),
                Adjuster(id: .crosshair_correction, adjustment: .double(0)),

                Adjuster(id: .angle_adjustment_type, adjustment: .int(1)),
                Adjuster(id: .angle_adjustment_display_type, adjustment: .int(1)),

                Adjuster(id: .default_boat_type, adjustment: .int(2), allowedError: 1),
            ],
            recommend: [
                Adjuster(id: .default_boat_type, adjustment: .int(2)),
                Adjuster(id: .show_angle_errors, adjustment: .boolean(true)),
                Adjuster(id: .mismeasure_warning_enabled, adjustment: .boolean(true)),
                Adjuster(id: .direction_help_enabled, adjustment: .boolean(true)),
            ]
        )
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
                return try JSONDecoder().decode(Results.self, from: data)
            }
        } catch {
            throw AdjustmentError.executionError
        }
        return nil
    }

    struct Results: Codable {
        let breaking: [NinBotSetting]
        let recommend: [NinBotSetting]
    }

    enum AdjustmentError: LocalizedError {
        case toolNotFound, encodingError, executionError, noResultError
    }
}
