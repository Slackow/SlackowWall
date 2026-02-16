//
//  MinecraftAdjuster.swift
//  SlackowWall
//
//  Created by Andrew on 2/11/26.
//

import Foundation

class MinecraftAdjuster {

    static let mouseSensTextRegex = /^mouseSensitivity:([\d.]+)$/.anchorsMatchLineEndings()

    func fix(instance inst: TrackedInstance) async {
        let trackingManager = TrackingManager.shared
        let boatEyeSensitivity = Settings[\.utility].boatEyeSensitivity

        let fm = FileManager.default
        let path = inst.info.path
        let optionsPath = "\(path)/options.txt"
        let standardSettingsTxt = "\(path)/config/standardoptions.txt"
        let standardSettingsJson = "\(path)/config/mcsr/standardsettings.json"
        let hasStandardSettings = inst.hasMod(.standardSettings)
        if hasStandardSettings
            && !(fm.fileExists(atPath: standardSettingsJson)
                || fm.fileExists(atPath: standardSettingsTxt))
        {
            LogManager.shared.appendLog(
                "Cannot figure out how to fix standard settings \(inst.name), skipping.")
            return
        }
        await trackingManager.killAndWait(pid: inst.pid)
        do {
            let contents = try String(contentsOfFile: optionsPath, encoding: .utf8)
            let replacement = contents.replacing(MinecraftAdjuster.mouseSensTextRegex) { _ in
                "mouseSensitivity:\(boatEyeSensitivity)"
            }.replacing("fullscreen:true", with: "fullscreen:false")
            try replacement.write(
                to: URL(filePath: optionsPath), atomically: true, encoding: .utf8)
            LogManager.shared.appendLog(
                "Wrote \(boatEyeSensitivity) to options.txt \(inst.name)")
        } catch {
            LogManager.shared.appendLog(
                "Failed to write to options.txt \(inst.name), skipping.", error)
        }
        if hasStandardSettings {
            do {
                let rootStandardSettingsTxt = followStandardSettingsTxt(
                    path: URL(filePath: standardSettingsTxt))
                let contents = try String(contentsOf: rootStandardSettingsTxt, encoding: .utf8)
                let replacement = contents.replacing(MinecraftAdjuster.mouseSensTextRegex) { _ in
                    "mouseSensitivity:\(boatEyeSensitivity)"
                }.replacing("fullscreen:true", with: "fullscreen:false")
                try replacement.write(
                    to: URL(filePath: standardSettingsTxt), atomically: true, encoding: .utf8)
                LogManager.shared.appendLog(
                    "Wrote \(boatEyeSensitivity) to standardoptions.txt \(inst.name)")
            } catch {
                LogManager.shared.appendLog(
                    "Failed to write to standardoptions.txt \(inst.name), skipping.", error)
            }
            do {
                // TODO: The logic for JSON file
                guard let contents = try? Data(contentsOf: URL(filePath: standardSettingsJson)),
                    var json = (try? JSONSerialization.jsonObject(with: contents, options: [])) as? [String: Any]
                else {
                    LogManager.shared.appendLog(
                        "Failed to read to standardsettings.json \(inst.name), skipping.")
                    return
                }
                json["mouseSensitivity"] = ["value": boatEyeSensitivity, "enabled": true]
                json["fullscreen"] = ["value": false, "enabled": true]

                let replacement = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                try replacement.write(to: URL(filePath: standardSettingsJson), options: .atomic)

                LogManager.shared.appendLog(
                    "Wrote \(boatEyeSensitivity) to standardsettings.json \(inst.name)")
            } catch {
                LogManager.shared.appendLog(
                    "Failed to write to standardsettings.json \(inst.name), skipping.", error)
            }
        }

    }

    func get(instance: TrackedInstance) throws -> Results {
        let path = instance.info.path
        let optionsPath = "\(path)/options.txt"
        let boatEyeSensitivity = Settings[\.utility].boatEyeSensitivity

        var breaking: [MinecraftResult] = []

        let contents = try String(contentsOfFile: optionsPath, encoding: .utf8)
        if contents.contains("fullscreen:true") {
            breaking.append(
                MinecraftResult(
                    id: .fullscreen,
                    oldValue: .boolean(true),
                    newValue: .boolean(false)
                ))
        }
        guard let match = try MinecraftAdjuster.mouseSensTextRegex.firstMatch(in: contents),
            let sens = Double(match.output.1)
        else {
            // TODO: can't get sensitivity, what do I do?
            throw AdjustmentError.optionsNotFound
        }
        if abs(sens - boatEyeSensitivity) > 0.0000001 {
            breaking.append(
                MinecraftResult(
                    id: .mouseSensitivity,
                    oldValue: .double(sens),
                    newValue: .double(boatEyeSensitivity)
                ))
        }

        return Results(breaking: breaking)
    }

    private func followStandardSettingsTxt(path: URL) -> URL {
        if let content = try? String(contentsOf: path, encoding: .utf8),
            let firstLine = content.components(separatedBy: "\n").first,
            FileManager.default.fileExists(atPath: firstLine)
        {
            followStandardSettingsTxt(path: URL(filePath: firstLine))
        } else {
            path
        }
    }

    struct Results {
        var breaking: [MinecraftResult]
    }

    struct MinecraftResult: Hashable {
        var id: MinecraftSetting
        var oldValue: MinecraftValue
        var newValue: MinecraftValue
    }

    enum MinecraftValue: Hashable, CustomStringConvertible {
        case boolean(Bool)
        case double(Double)
        case string(String)

        var description: String {
            switch self {
                case .boolean(let value):
                    return value ? "On" : "Off"
                case .double(let value):
                    let formatted = value.formatted(.number.precision(.fractionLength(0...8)))
                    return formatted
                case .string(let value):
                    return value
            }
        }
    }

    enum MinecraftSetting: String {
        case mouseSensitivity, fullscreen

        var name: String {
            switch self {
                case .mouseSensitivity: "Mouse Sensitivity"
                case .fullscreen: "Fullscreen"
            }
        }

        var description: String? {
            switch self {
                case .mouseSensitivity:
                    return """
                        Your Minecraft sensitivity must be the same as in SlackowWall and Ninjabrain Bot.
                        """
                case .fullscreen:
                    return "Fullscreen should be off for BoatEye."
            }
        }

        var warning: String? {
            switch self {
                case .mouseSensitivity:
                    let sensitivity = Settings[\.utility].boatEyeSensitivity
                    return """
                        This will change your Minecraft sensitivity to ~\(Int(sensitivity * 200))%.\nYou can \
                        compensate for this \
                        with Sensitivity Scaling (found under Utility Settings)
                        """
                default:
                    return nil
            }
        }

        func valueName(_ value: MinecraftValue) -> String {
            value.description
        }
    }

    enum AdjustmentError: LocalizedError {
        case optionsNotFound, encodingError, decodingError, executionError, noResultError
    }
}
