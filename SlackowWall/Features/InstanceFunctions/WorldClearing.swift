//
//  WorldClearing.swift
//  SlackowWall
//
//  Created by Andrew on 6/13/25.
//

import Foundation

final class WorldClearing {

    static func worldsToDelete(at path: String) throws -> [URL] {
        let fileManager = FileManager.default
        let savesURL = URL(filePath: path)

        guard fileManager.fileExists(atPath: savesURL.path)
        else { return [] }

        let worldURLs = try fileManager.contentsOfDirectory(
            at: savesURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        let candidates: [(url: URL, date: Date)] = worldURLs.compactMap { url in
            guard shouldRemove(path: url.path) else { return nil }
            let date =
                (try? url.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate)
                ?? Date.distantPast
            return (url, date)
        }

        return
            candidates
            .sorted { $0.date > $1.date }  // newest first
            .dropFirst(40)
            .map(\.url)
    }

    @discardableResult
    static func deleteWorlds(
        _ worlds: [URL],
        progress: ((Int, Int) -> Void)? = nil  // (cleared, total)
    ) -> Int {
        guard !worlds.isEmpty else { return 0 }

        let fileManager = FileManager.default
        let lock = NSLock()
        var cleared = 0
        let group = DispatchGroup()

        for url in worlds {
            group.enter()
            DispatchQueue.global(qos: .utility).async {
                defer { group.leave() }
                do {
                    try fileManager.removeItem(at: url)
                    lock.lock()
                    cleared += 1
                    progress?(cleared, worlds.count)
                    let progressCount = cleared
                    lock.unlock()
                    if progressCount % 300 == 0 {
                        LogManager.shared.appendLog("Cleared \(progressCount)/\(worlds.count)")
                    }
                } catch {
                    LogManager.shared.appendLog(
                        "Failed to delete world \"\(url.lastPathComponent)\": \(error)")
                }
            }
        }

        group.wait()
        return cleared
    }

    static func shouldRemove(path: String) -> Bool {
        let url = URL(filePath: path)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path)
        else { return false }

        if fileManager.fileExists(atPath: url.appending(path: "Reset Safe.txt").path) {
            return false
        }

        let name = url.lastPathComponent

        if name.hasPrefix("Benchmark Reset #") {
            return true
        }

        if !fileManager.fileExists(atPath: url.appending(path: "level.dat").path) {
            return false
        }

        if name.hasPrefix("_") {
            return false
        }

        return name.hasPrefix("New World")
            || name.contains("Speedrun #")
            || name.contains("Practice Seed")
            || name.contains("Seed Paster")
    }
}
