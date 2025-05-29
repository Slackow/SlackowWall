//
//  PacemanManager.swift
//  SlackowWall
//
//  Created by Andrew on 5/27/25.
//

import Foundation

@MainActor class PacemanManager: Manager, ObservableObject {
    static let shared = PacemanManager()
    let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
        ".config/PaceMan/options.json")
    var pacemanConfig: PacemanConfig {
        didSet {
            do {
                try saveConfig()
            } catch {
                LogManager.shared.appendLog("Error saving Paceman Config: \(error)")
            }
        }
    }

    private var wrapperProcess: Process? = nil
    @Published private(set) var isRunning: Bool = false

    private init() {
        let fm = FileManager.default
        if let data = try? Data(contentsOf: configPath),
            let cfg = try? JSONDecoder().decode(PacemanConfig.self, from: data)
        {
            pacemanConfig = cfg
        } else {
            LogManager.shared.appendLog("No Paceman config found, creating default.")
            do {
                try fm.createDirectory(
                    at: configPath.deletingLastPathComponent(), withIntermediateDirectories: true)
            } catch {
                LogManager.shared.appendLog("Failed to create default Paceman config: \(error)")
            }
            pacemanConfig = PacemanConfig()
        }
    }

    func startPaceman() {
        guard wrapperProcess == nil else { return }  // already running

        let wrapperPath = Bundle.main.bundlePath.appending("/Contents/MacOS/PacemanWrapper")
        //        else {
        //            LogManager.shared.appendLog("PacemanWrapper missing from bundle")
        //
        //            return
        //        }
        guard
            let jarURL = Bundle.main.url(
                forResource: "paceman-tracker-0.7.0",
                withExtension: "jar")
        else {
            LogManager.shared.appendLog("paceman-tracker.jar missing from bundle")
            return
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: wrapperPath)
        proc.arguments = [jarURL.path]

        // When helper exits (for any reason) bring state back to idle.
        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.wrapperProcess = nil
                self?.isRunning = false
            }
        }

        do {
            try proc.run()
            wrapperProcess = proc
            isRunning = true
        } catch {
            LogManager.shared.appendLog("Failed to start PacemanWrapper: \(error)")
        }
    }

    func stopPaceman() {
        guard let proc = wrapperProcess, proc.isRunning else { return }

        Task.detached { [weak self] in
            proc.terminate()
            proc.waitUntilExit()  // wait off‑main‑thread
            await MainActor.run {
                // only clear if we’re still pointing at this proc
                if self?.wrapperProcess === proc {
                    self?.wrapperProcess = nil
                    self?.isRunning = false
                }
            }
        }
    }

    private func saveConfig() throws {
        let data = try JSONEncoder().encode(pacemanConfig)
        let object = try JSONSerialization.jsonObject(with: data)
        let pretty = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        try pretty.write(to: configPath, options: .atomic)
    }

    static func testToken(token: String) async throws -> String? {
        guard let url = URL(string: "https://paceman.gg/api/test") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("SlackowWall/1.1.0", forHTTPHeaderField: "User-Agent")
        req.httpBody = #"{"accessKey": "\#(token)"}"#.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard 200..<300 ~= http.statusCode else { return nil }
        let uuid =
            String(data: data, encoding: .utf8).map { $0.lowercased() }.flatMap { a in
                try? /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.firstMatch(
                    in: a)?.output
            } ?? ""
        return uuid.replacingOccurrences(of: "-", with: "")
    }
}
