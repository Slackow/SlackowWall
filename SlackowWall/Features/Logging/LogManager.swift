//
//  LogManager.swift
//  SlackowWall
//
//  Created by Kihron on 5/27/24.
//

import AppKit
import Gzip
import SwiftUI

class LogManager {
    private let logDirectory = "/tmp/SlackowWall/Logs/"

    static let shared = LogManager()

    private var logPath: String {
        return logDirectory + "latest.log"
    }

    init() {
        createLogDirectory()
        createLogFile()
        prependSystemInfo()
        appendLogSection("Log Output")
    }

    private func createLogDirectory() {
        let fileManager = FileManager.default
        let logDirectoryURL = URL(filePath: logDirectory)

        do {
            try fileManager.createDirectory(
                at: logDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create log directory: \(error)")
        }
    }

    private func createLogFile() {
        let fileManager = FileManager.default
        let logURL = URL(filePath: logPath)

        if fileManager.fileExists(atPath: logPath) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: logPath)
                if let creationDate = attributes[.creationDate] as? Date {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                    let dateString = dateFormatter.string(from: creationDate)
                    let backupLogPath = logDirectory + "\(dateString).log"
                    let backupLogURL = URL(filePath: backupLogPath)

                    try fileManager.moveItem(at: logURL, to: backupLogURL)

                    compressLogFile(at: backupLogURL)
                } else {
                    print("Failed to get creation date of log file")
                }
            } catch {
                print("Failed to rename log file: \(error)")
            }
        }

        // Create new log file
        fileManager.createFile(atPath: logPath, contents: nil, attributes: nil)
    }

    private func compressLogFile(at url: URL) {
        let fileManager = FileManager.default
        let sourceURL = url
        let destinationURL = sourceURL.appendingPathExtension("gz")

        do {
            let sourceData = try Data(contentsOf: sourceURL)
            let compressedData = try sourceData.gzipped(level: .bestCompression)

            try compressedData.write(to: destinationURL)
            try fileManager.removeItem(at: sourceURL)

            print("Successfully compressed log file to: \(destinationURL.path)")
        } catch {
            print("Failed to compress log file: \(error)")
        }
    }

    @discardableResult func logPath(
        _ path: String, showInConsole: Bool = true, includeTimestamp: Bool = true
    ) -> Self {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let sanitizedPath = path.replacingOccurrences(of: homeDirectory, with: "~")
        return appendLog(
            sanitizedPath, showInConsole: showInConsole, includeTimestamp: includeTimestamp)
    }

    @discardableResult func appendLog(
        _ items: Any..., showInConsole: Bool = true, includeTimestamp: Bool = true
    ) -> Self {
        let logURL = URL(filePath: logPath)
        let message = items.map { String(describing: $0) }.joined(separator: " ")

        let timestamp: String
        if includeTimestamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss.SSS"
            timestamp = "[\(dateFormatter.string(from: Date()))] "
        } else {
            timestamp = ""
        }

        let messageWithNewline = timestamp + "- " + message + "\n"

        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()

            let data = Data(messageWithNewline.utf8)
            try fileHandle.write(contentsOf: data)

            if showInConsole {
                print(message)
            }
        } catch {
            print("Failed to write to log file: \(error)")
        }
        return self
    }

    @discardableResult func appendLogSection(_ title: String) -> Self {
        let logURL = URL(filePath: logPath)
        let titleWithNewline = title + ":\n"

        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()

            let data = Data(titleWithNewline.utf8)
            try fileHandle.write(contentsOf: data)

        } catch {
            print("Failed to write to log file: \(error)")
        }
        return self
    }

    @discardableResult func appendLogNewLine() -> Self {
        let logURL = URL(filePath: logPath)
        let newLine = "\n"

        do {
            let fileHandle = try FileHandle(forWritingTo: logURL)
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: Data(newLine.utf8))
        } catch {
            print("Failed to write to log file: \(error)")
        }
        return self
    }

    private func prependSystemInfo() {
        appendLogSection("SlackowWall\nSystem Information")

        // Get macOS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString =
            "macOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        appendLog(osVersionString, showInConsole: false, includeTimestamp: false)

        // Get hardware information
        var hwModel = ""
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        if size > 0 {
            var model = [CChar](repeating: 0, count: Int(size))
            sysctlbyname("hw.model", &model, &size, nil, 0)
            hwModel = String(cString: model)
        }
        appendLog("Hardware Model: \(hwModel)", showInConsole: false, includeTimestamp: false)

        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        appendLog(
            String(format: "Memory: %.2f GB", Double(physicalMemory) / 1073741824.0),
            showInConsole: false, includeTimestamp: false)

        let processorCount = ProcessInfo.processInfo.processorCount
        appendLog(
            "Processor Count: \(processorCount)", showInConsole: false, includeTimestamp: false)

        // Get app version
        if let appVersion = UpdateManager.shared.appVersion,
            let buildNumber = UpdateManager.shared.appBuild
        {
            appendLog(
                "App Version: \(appVersion) (\(buildNumber))", showInConsole: false,
                includeTimestamp: false)
        } else {
            appendLog("App Version: Unknown", showInConsole: false, includeTimestamp: false)
        }
        if let hiDPI = NSScreen.primary?.backingScaleFactor {
            appendLog(
                "Scaling: \(hiDPI == 1 ? "LoDPI" : "HiDPI") (\(hiDPI))", showInConsole: false,
                includeTimestamp: false)
        }

        appendLogNewLine()
    }

    func openLogFolder() {
        let logFolderURL = URL(filePath: logDirectory)

        if FileManager.default.fileExists(atPath: logDirectory) {
            NSWorkspace.shared.open(logFolderURL)
        }
    }

    @MainActor
    func openLatestLogInConsole() {
        logCurrentProfile()
        let logFileURL = URL(filePath: logPath)

        if FileManager.default.fileExists(atPath: logPath) {
            NSWorkspace.shared.open(logFileURL)
        }
    }

    @MainActor
    func uploadLog(callback: @escaping (String, String?) -> Void = { _, _ in }) {
        logCurrentProfile()

        // Read the full contents of the newest log file.
        guard let logContents = try? String(contentsOfFile: logPath, encoding: .utf8) else {
            appendLog("Failed to read log file for mclo.gs upload")
            return
        }

        // Prepare the POST request for mclo.gs
        let mclogsURL = URL(string: "https://api.mclo.gs/1/log")!
        var request = URLRequest(url: mclogsURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // mclo.gs expects a single 'content' form field with the log text
        let bodyString =
            "content="
            + (logContents.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        request.httpBody = Data(bodyString.utf8)

        // Perform the upload asynchronously.
        Task(priority: .userInitiated) {
            let message: String
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    appendLog("mclo.gs response was not an HTTPURLResponse")
                    return
                }

                // Expecting JSON: { "success": true, "url": "https://mclo.gs/XXXX", ... }
                guard httpResponse.statusCode == 200 else {
                    let body = String(data: data, encoding: .utf8) ?? "<no body>"
                    appendLog("mclo.gs upload failed (\(httpResponse.statusCode)): \(body)")
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let success = json["success"] as? Bool, success,
                    let urlString = json["url"] as? String
                {
                    message = "Log uploaded to mclo.gs: \(urlString)"
                    callback(message, urlString)
                    return
                } else {
                    let body = String(data: data, encoding: .utf8) ?? "<unparseable json>"
                    message = "mclo.gs upload returned unexpected payload: \(body)"
                }

            } catch {
                message = "Error uploading log to mclo.gs: \(error)"
            }
            callback(message, nil)
        }
    }

    @MainActor
    func logSensitivityDetection() {
        let trackingManager = TrackingManager.shared
        let boatEyeSens = Settings[\.utility].boatEyeSensitivity
        appendLogNewLine()
        if trackingManager.trackedInstances.isEmpty {
            appendLog("No Instance open")
        }
        for instance in trackingManager.trackedInstances {
            guard
                let file = try? String(
                    contentsOfFile: "\(instance.info.path)/options.txt", encoding: .utf8),
                let match = (try? UtilitySettings.mouseSensTextRegex.firstMatch(in: file))?.output
                    .1,
                let sens = Double(match)
            else {
                appendLog("Could not find sensitivity in options.txt for \(instance.name)")
                continue
            }
            if abs(sens - boatEyeSens) > 0.0000001 {
                appendLog(
                    "\(instance.name) has a sensitivity of '\(sens)' but the app thinks it's '\(boatEyeSens)'"
                )
            } else {
                appendLog("Boateye Sens verified for \(instance.name)")
            }
        }
    }

    func logNinbotSettings() {
        appendLogNewLine()
        appendLog("Ninjabrain Bot Settings")
        let plistPath = ("~/Library/Preferences/com.apple.java.util.prefs.plist" as NSString)
            .expandingTildeInPath
        let keyPathComponents = ["/", "ninjabrainbot/"]
        func value(at path: [String], in object: Any) -> Any? {
            var current: Any? = object
            for key in path {
                guard let dict = current as? [String: Any] else { return nil }
                current = dict[key]
            }
            return current
        }
        func prettyJSONString(from any: Any) -> String? {
            // If it's Data, try JSON -> pretty string
            let options: JSONSerialization.WritingOptions = [
                .prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed,
            ]
            if let data = any as? Data {
                if let obj = try? JSONSerialization.jsonObject(with: data),
                    JSONSerialization.isValidJSONObject(obj),
                    let pretty = try? JSONSerialization.data(withJSONObject: obj, options: options),
                    let s = String(data: pretty, encoding: .utf8)
                {
                    return s
                }
            }
            // If it's String, try parse as JSON first, else return raw string
            if let s = any as? String {
                if let obj = try? JSONSerialization.jsonObject(with: Data(s.utf8)),
                    JSONSerialization.isValidJSONObject(obj),
                    let pretty = try? JSONSerialization.data(withJSONObject: obj, options: options),
                    let prettyStr = String(data: pretty, encoding: .utf8)
                {
                    return prettyStr
                }
                return s
            }
            // If it's already a plist dictionary/array, convert via JSONSerialization for readability
            if let dict = any as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dict, options: options),
                let s = String(data: data, encoding: .utf8)
            {
                return s
            }
            if let arr = any as? [Any],
                let data = try? JSONSerialization.data(withJSONObject: arr, options: options),
                let s = String(data: data, encoding: .utf8)
            {
                return s
            }
            return nil
        }
        let plistURL = URL(filePath: plistPath)
        guard let data = try? Data(contentsOf: plistURL),
            let plist = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil),
            let v = value(at: keyPathComponents, in: plist),
            let logOutput = prettyJSONString(from: v)
        else { return }
        logPath(logOutput, includeTimestamp: false)
    }

    @MainActor
    func logCurrentProfile() {
        logSensitivityDetection()
        logNinbotSettings()
        appendLogNewLine()
        appendLog("Current Settings")

        do {
            let prefs = Settings[\.self]
            let data = try JSONEncoder().encode(prefs)
            let json = try JSONSerialization.jsonObject(with: data)
            let prettyJSONData = try JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed])
            let prettyJSON =
                String(data: prettyJSONData, encoding: .utf8)
                ?? "Data could not be converted to string"
            logPath(prettyJSON, includeTimestamp: false)
        } catch {
            appendLog("Unable to encode Preferences to JSON")
        }
    }
}
