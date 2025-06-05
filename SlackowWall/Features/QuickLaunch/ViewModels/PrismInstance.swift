//
//  PrismInstance.swift
//  SlackowWall
//
//  Created by Andrew on 5/30/25.
//

import AppKit
import SwiftUI

struct PrismInstance: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let icon: NSImage
}

@MainActor
final class PrismInstanceStore: ObservableObject {
    @Published private(set) var instances: [PrismInstance] = []
    @Published private(set) var favourites: [PrismInstance] = []

    private let favouritesKey = "quickLaunchPinnedInstances"

    init() {
        reload()
    }

    // MARK: Discovery

    func reload() {
        instances = discoverInstances()
        loadFavourites()
    }

    private func discoverInstances() -> [PrismInstance] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = home.appendingPathComponent(
            "Library/Application Support/PrismLauncher/instances")
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
                url.appendingPathComponent($0)
            }
            let iconURL = iconCandidates.first { FileManager.default.fileExists(atPath: $0.path) }
            let iconImage =
                iconURL.flatMap { NSImage(contentsOf: $0) } ?? NSImage(named: "minecraft_logo")
                ?? NSImage()

            return PrismInstance(name: name, icon: iconImage)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func loadFavourites() {
        let names = UserDefaults.standard.stringArray(forKey: favouritesKey) ?? []
        favourites = names.compactMap { name in
            instances.first { $0.name == name }
        }
    }

    func isFavourite(_ instance: PrismInstance) -> Bool {
        favourites.contains(instance)
    }

    func toggleFavourite(_ instance: PrismInstance) {
        var names = UserDefaults.standard.stringArray(forKey: favouritesKey) ?? []
        if let idx = names.firstIndex(of: instance.name) {
            names.remove(at: idx)
        } else {
            names.insert(instance.name, at: 0)
        }
        UserDefaults.standard.set(names, forKey: favouritesKey)
        loadFavourites()
    }

    func launch(_ instance: PrismInstance) {
        let task = Process()
        let openInst =
            #"killall prismlauncher;open -a "Prism Launcher" --args --launch "\#(instance.name)""#
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", openInst]
        try? task.run()
    }
}
