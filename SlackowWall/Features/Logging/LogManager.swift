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

    @discardableResult func logPath(_ path: String, showInConsole: Bool = true) -> Self {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let sanitizedPath = path.replacingOccurrences(of: homeDirectory, with: "~")
        return appendLog(sanitizedPath, showInConsole: showInConsole)
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

            if let data = messageWithNewline.data(using: .utf8) {
                try fileHandle.write(contentsOf: data)
            }

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

            if let data = titleWithNewline.data(using: .utf8) {
                try fileHandle.write(contentsOf: data)
            }

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

            if let data = newLine.data(using: .utf8) {
                try fileHandle.write(contentsOf: data)
            }

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
            appendLog("HiDPI: \(hiDPI)", showInConsole: false, includeTimestamp: false)
        }

        appendLogNewLine()
    }

    func openLogFolder() {
        let logFolderURL = URL(filePath: logDirectory)

        if FileManager.default.fileExists(atPath: logDirectory) {
            NSWorkspace.shared.open(logFolderURL)
        }
    }

    func openLatestLogInConsole() {
        logCurrentProfile()
        let logFileURL = URL(filePath: logPath)

        if FileManager.default.fileExists(atPath: logPath) {
            NSWorkspace.shared.open(logFileURL)
        }
    }

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
        request.httpBody = bodyString.data(using: .utf8)

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

    func logCurrentProfile() {
        appendLogNewLine()
        appendLog("Current Settings")

        do {
            let prefs = Settings[\.self]
            let data = try JSONEncoder().encode(prefs)
            let json = try JSONSerialization.jsonObject(with: data)
            let prettyJSONData = try JSONSerialization.data(
                withJSONObject: json, options: [.prettyPrinted])
            let prettyJSON =
                String(data: prettyJSONData, encoding: .utf8)
                ?? "Data could not be converted to string"
            appendLog(prettyJSON, includeTimestamp: false)
        } catch {
            appendLog("Unable to encode Preferences to JSON")
        }
    }
}
