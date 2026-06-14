//
//  NinjabrainManager.swift
//  SlackowWall
//
//  Created by Andrew on 3/29/26.
//

import EventSource
import SwiftUI
import ZIPFoundation

class NinjabrainManager: Manager, ObservableObject {

    static var shared = NinjabrainManager()

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
            Task {
                try? await Task.sleep(for: .seconds(2))
            }
            return true
        }
        return false
    }

    private static var ninbotApp: NSRunningApplication?

    private static func getNinbot() -> NSRunningApplication? {
        if let ninbotApp, !ninbotApp.isTerminated {
            return ninbotApp
        }

        if let ninjabrainBotProc,
            ninjabrainBotProc.isRunning,
            let ninbotApp = NSWorkspace.shared.runningApplications.first(where: {
                $0.processIdentifier == ninjabrainBotProc.processIdentifier
            })
        {
            NinjabrainManager.ninbotApp = ninbotApp
            return ninbotApp
        }

        let ninbotApp = NSWorkspace.shared.runningApplications.filter(isNinjabrainBot).first
        NinjabrainManager.ninbotApp = ninbotApp
        return ninbotApp
    }

    @MainActor
    static func changeVisibility(canSee: Bool? = nil) {
        guard let ninbot = getNinbot() else {
            LogManager.shared.appendLog("Ninbot not open.")
            return
        }
        let newState = canSee ?? ninbot.isHidden
        if ninbot.isHidden == newState {
            if newState {
                ninbot.unhide()
            } else {
                ninbot.hide()
            }
            LogManager.shared.appendLog("Ninbot \(newState ? "un" : "")hidden.")
        }
    }

    static func isNinjabrainBot(app: NSRunningApplication) -> Bool {
        guard let args = Utilities.processArguments(pid: app.processIdentifier) else {
            return false
        }

        if let jarIdx = args.firstIndex(of: "-jar"), let jarName = args[safe: jarIdx + 1],
            jarName.hasPrefix("/"), jarName.localizedCaseInsensitiveContains("Ninjabrain"), jarName.hasSuffix(".jar"),
            let archive = try? Archive(
                url: URL(filePath: jarName), accessMode: .read, pathEncoding: nil),
            let entry = archive["META-INF/MANIFEST.MF"]
        {
            var manifestData = Data()
            guard
                (try? archive.extract(entry) { data in
                    manifestData.append(data)
                }) != nil
            else {
                return false
            }

            return manifestData.contains(Data("Main-Class: ninjabrainbot.Main".utf8))
        }
        return false
    }

    var strongholdTask: Task<Void, Error>?

    func listenToNinbot() {
        guard let url = URL(string: "http://localhost:52533/api/v1/stronghold/events")
        else { return }
        strongholdTask?.cancel()
        strongholdTask = Task {
            try? await Task.sleep(for: .seconds(2))
            let eventSource = EventSource(timeoutIntervalForRequest: .infinity, timeoutIntervalForResource: .infinity)
            let urlRequest = URLRequest(url: url)
            let dataTask = eventSource.dataTask(for: urlRequest)

            for await event in dataTask.events() {
                switch event {
                    case .open:
                        print("Connection was opened.")
                    case .error(let error):
                        print("Received an error:", error.localizedDescription)
                    case .event(let event):
                        let decoder = JSONDecoder()
                        if let data = event.data,
                            let result = try? decoder.decode(StrongholdResult.self, from: Data(data.utf8))
                        {
                            strongholdResult = result
                            if Settings[\.utility].ninjabrainBotAutoAppear {
                                NinjabrainManager.changeVisibility(canSee: result.hasResult)
                            }
                        }
                    case .closed:
                        print("Connection was closed.")
                }
            }
        }
    }

    @Published
    var strongholdResult: StrongholdResult?

    struct StrongholdResult: Codable {
        let eyeThrows: [EyeThrow]
        let resultType: String
        var hasResult: Bool {
            resultType != "NONE"
        }

        struct EyeThrow: Codable {
            let correctionIncrements: Int
        }
    }
}
