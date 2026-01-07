//
// Created by Kihron on 1/28/23.
//

/*
 For Macro Makers and Verifiers
 The State File is created while the game is running and can be found in .minecraft/wpstateout.txt. The file contains a single line of text containing information about the game's current state, and overwrites itself whenever the state changes. The following states will appear as lines in the file:

 waiting                                      | w  119 0x77
 inworld,paused                               | s  115 0x73
 inworld,unpaused                             | a  97  0x61
 inworld,gamescreenopen                       | e  101 0x65
 title                                        | t  116 0x74
 generating,[percent] (before preview starts) | g  103 0x67
 previewing,[percent]                         | p  112 0x70
 */

import SwiftUI
import ZIPFoundation

class InstanceInfo: CustomStringConvertible {
    var state: InstanceState = .title
    var prevState: InstanceState = .title
    var statePath: String {
        return path.isEmpty ? "" : "\(path)/wpstateout.txt"
    }
    let path: String
    let version: String
    let pid: pid_t
    lazy var port: UInt16 = readBoundlessPort()
    var untilF3: Int = 0
    var checkState: CheckingMode = .NONE
    var isBoundless: Bool {
        mods.contains(where: { "boundlesswindow" == $0.id })
    }
    var mods: [ModInfo] = []

    init(pid: pid_t, path: String, version: String) {
        self.pid = pid
        self.path = path
        self.version = version
        Task {
            updateModInfo()
            try? await Task.sleep(for: .seconds(0.95))
            DispatchQueue.main.async {
                if Settings[\.behavior].utilityMode {
                    ShortcutManager.shared.resizeBase(pid: pid)
                } else {
                    ShortcutManager.shared.resizeReset(pid: pid)
                }
            }
        }
    }

    func readBoundlessPort() -> UInt16 {
        if let contents = FileManager.default.contents(atPath: "\(path)/boundless_port.txt"),
            !contents.isEmpty,
            let port = String(data: contents, encoding: .utf8),
            let port = UInt16(port)
        {
            LogManager.shared.appendLog("Port: \(port) for \(pid)")
            return port
        } else {
            return 0
        }
    }

    // for any world preview state output, this will map it to a unique byte and store it into state.
    @discardableResult func updateState(force: Bool = false) -> Bool {
        LogManager.shared.appendLog("Attempting to update instance state...")

        // Skip updating state if not forced and checkState is .NONE
        guard force || checkState != .NONE else {
            return false
        }

        // Update previous state
        prevState = state

        // Attempt to read file data
        guard let fileData = FileManager.default.contents(atPath: statePath), !fileData.isEmpty
        else {
            LogManager.shared.logPath("Error: Failed to read file \(statePath)")
            return false
        }

        // Update state based on file data
        var newState = fileData[safe: 0] ?? 0
        // is one of the "inworld" variants
        if newState == 0x69 {
            newState = fileData[safe: 11] ?? newState
        }
        if let newState = InstanceState(rawValue: newState) {
            state = newState
            LogManager.shared.appendLog("Updated State:", state)
        } else {
            LogManager.shared.appendLog("Failed to update state:", newState)
        }
        return prevState != state
    }

    var description: String {
        "s: \(state), pstate: \(prevState), mode: \(checkState), p: \(path), pid: \(pid)"
    }

    func updateModInfo() {
        guard !path.isEmpty else { return }
        let fileManager = FileManager.default
        if let contents = try? fileManager.contentsOfDirectory(atPath: path + "/mods/") {
            self.mods = contents.map { URL(filePath: path + "/mods/\($0)") }
                .filter { $0.pathExtension == "jar" }
                .compactMap { InstanceInfo.extractModInfo(fromJarAt: $0) }
            LogManager.shared.appendLog("mods", mods.map(\.id))
        }
    }

    private static func extractModInfo(
        fromJarAt url: URL, archiveAction: ((Archive, ModInfo, URL) -> Void)? = nil
    ) -> ModInfo? {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            let jsonEntry = "fabric.mod.json"

            guard let entry = archive[jsonEntry] else {
                //                print("JSON file not found in JAR.")
                return nil
            }

            var jsonData = Data()
            _ = try archive.extract(entry) { data in
                jsonData.append(data)
            }

            // Convert data to a string for preprocessing
            if var jsonString = String(data: jsonData, encoding: .utf8) {
                // Fix the description field by escaping newlines
                if let descriptionRange = jsonString.range(
                    of: #""description": "[^"]+""#, options: .regularExpression)
                {
                    var descriptionString = String(jsonString[descriptionRange])
                    descriptionString = descriptionString.replacingOccurrences(
                        of: "\n", with: "\\n")
                    jsonString.replaceSubrange(descriptionRange, with: descriptionString)
                }
                // Convert back to data
                jsonData = Data(jsonString.utf8)
            }
            let decoder = JSONDecoder()
            decoder.allowsJSON5 = true
            var modInfo = try decoder.decode(ModInfo.self, from: jsonData)
            modInfo.filePath = url
            archiveAction?(archive, modInfo, url)
            return modInfo
        } catch DecodingError.dataCorrupted(let context) {
            LogManager.shared.appendLog("Data corrupted: \(context.debugDescription)")
            return nil
        } catch {
            LogManager.shared.appendLog("Error occurred: \(error)")
            return nil
        }
    }
}
