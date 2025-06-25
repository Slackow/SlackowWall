//
//  PrismInstanceStore.swift
//  SlackowWall
//
//  Created by Andrew on 5/30/25.
//

import AppKit
import SwiftUI

@MainActor
final class PrismInstanceStore: ObservableObject {
    @Published private(set) var instances: [PrismInstance] = []
    @Published private(set) var favorites: [PrismInstance] = []

    private let favoritesKey = "quickLaunchPinnedInstances"

    init() {
        reload()
    }

    func reload() {
        instances = discoverInstances()
        loadFavorites()
    }

    private func discoverInstances() -> [PrismInstance] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = home.appending(
            path: "Library/Application Support/PrismLauncher/instances/")
        guard
            let subdirs = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles])
        else { return [] }

        return subdirs.compactMap { url -> PrismInstance? in
            guard url.hasDirectoryPath else { return nil }
            let name = url.lastPathComponent

            // Look for the two possible icon paths
            let iconCandidates = [".minecraft/icon.png", "minecraft/icon.png"].map {
                url.appending(path: $0)
            }
            let iconURL = iconCandidates.first { FileManager.default.fileExists(atPath: $0.path) }
            let iconImage =
                iconURL.flatMap { NSImage(contentsOf: $0) } ?? NSImage(named: "minecraft_logo")
                ?? NSImage()

            return PrismInstance(name: name, icon: iconImage)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func loadFavorites() {
        let names = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        favorites = names.compactMap { name in
            instances.first { $0.name == name }
        }
    }

    func isFavorite(_ instance: PrismInstance) -> Bool {
        favorites.contains(instance)
    }

    func toggleFavorite(_ instance: PrismInstance) {
        var names = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        if let idx = names.firstIndex(of: instance.name) {
            names.remove(at: idx)
        } else {
            names.insert(instance.name, at: 0)
        }
        UserDefaults.standard.set(names, forKey: favoritesKey)
        loadFavorites()
    }

    func launch(_ instance: PrismInstance) {
        let task = Process()
        let openInst =
            """
            killall prismlauncher; \
            open -a "Prism Launcher" --args --launch "\(instance.name)" || \
            open -a "PrismLauncher" --args --launch "\(instance.name)"
            """

        task.launchPath = "/bin/sh"
        task.arguments = ["-c", openInst]
        try? task.run()
    }
}
