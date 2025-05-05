//
//  Settings.swift
//  SlackowWall
//
//  Created by Kihron on 5/3/25.
//

import SwiftUI
import Combine

@MainActor class Settings: ObservableObject {
    private let fileManager = FileManager.default

    static let shared: Settings = .init()

    @Published private(set) var currentProfile: UUID = .init() {
        didSet { preferences = loadSettings() }
    }

    @Published var preferences: Preferences

    private var storeTask: AnyCancellable!

    private init() {
        self.preferences = .init()
        self.currentProfile = Self.lastActiveProfile(baseURL: baseURL, fileManager: fileManager) ?? UUID()
        observePreferences()
    }

    private func observePreferences() {
        self.storeTask = self.$preferences.throttle(for: 2, scheduler: RunLoop.main, latest: true).sink {
            try? self.savePreferences($0)
        }
    }

    static subscript<T>(_ path: WritableKeyPath<Preferences, T>, suite: Settings = .shared) -> T {
        get {
            suite.preferences[keyPath: path]
        }
        set {
            suite.preferences[keyPath: path] = newValue
        }
    }

    private func loadSettings() -> Preferences {
        let url = settingsURL(for: currentProfile)
        LogManager.shared.appendLog("Active Profile:", currentProfile)

        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: false)
            return .init()
        }

        guard let json = try? Data(contentsOf: url),
              let prefs = try? JSONDecoder().decode(Preferences.self, from: json)
        else {
            return .init()
        }
        return prefs
    }

    private func loadSettings(from id: UUID) throws -> Preferences? {
        let url = settingsURL(for: id)

        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Preferences.self, from: data)
    }

    private func savePreferences(_ prefs: Preferences) throws {
        try savePreferences(prefs, to: settingsURL(for: currentProfile))
    }

    private func savePreferences(_ prefs: Preferences, to url: URL) throws {
        let data = try JSONEncoder().encode(prefs)
        let json = try JSONSerialization.jsonObject(with: data)
        let prettyJSON = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
        try prettyJSON.write(to: url, options: .atomic)
    }

    private var baseURL: URL {
        fileManager
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/SlackowWall", isDirectory: true)
            .appendingPathComponent("Profiles", isDirectory: true)
    }

    private func settingsURL(for id: UUID) -> URL {
        baseURL
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension("json")
    }
}

extension Settings {
    var availableProfiles: [(id: UUID, name: String)] {
        (try? fileManager.contentsOfDirectory(atPath: baseURL.path))?
            .compactMap { filename in
                guard filename.hasSuffix(".json"),
                      let id = UUID(uuidString: (filename as NSString).deletingPathExtension),
                      let prefs = try? loadSettings(from: id)
                else { return nil }
                return (id, prefs.profile.name)
            } ?? []
    }

    private static func lastActiveProfile(baseURL: URL, fileManager: FileManager) -> UUID? {
        try? fileManager.contentsOfDirectory(atPath: baseURL.path)
            .compactMap { filename -> UUID? in
                guard filename.hasSuffix(".json") else { return nil }

                let idString = (filename as NSString).deletingPathExtension
                guard let id = UUID(uuidString: idString) else { return nil }

                let url   = baseURL.appendingPathComponent(idString)
                    .appendingPathExtension("json")
                guard
                    let data  = try? Data(contentsOf: url),
                    let prefs = try? JSONDecoder().decode(Preferences.self, from: data),
                    prefs.profile.isActive
                else { return nil }

                return id
            }.first
    }

    func createProfile() {
        guard availableProfiles.count < 10 else { return }
        var prefs = preferences
        prefs.profile.id = UUID()
        prefs.profile.name = generateProfileName()

        do {
            let url = settingsURL(for: prefs.profile.id)
            guard !fileManager.fileExists(atPath: url.path) else { throw ProfileError.alreadyExists }

            try savePreferences(prefs, to: url)
            try switchProfile(to: prefs.profile.id)
        } catch {
            LogManager.shared.appendLog("Profile Error:", error)
        }
    }

    func switchProfile(to id: UUID) throws {
        guard id != currentProfile else { return }
        guard availableProfiles.contains(where: { $0.id == id }) else { throw ProfileError.notFound }

        try setActiveFlag(for: currentProfile, to: false)
        try setActiveFlag(for: id, to: true)

        currentProfile = id
    }

    func deleteCurrentProfile() {
        do {
            guard availableProfiles.count > 1 else { throw ProfileError.cannotDeleteOnlyProfile }
            guard let idx = availableProfiles.firstIndex(where: { $0.id == currentProfile }) else { throw ProfileError.notFound }

            print(settingsURL(for: currentProfile))
            try fileManager.removeItem(at: settingsURL(for: currentProfile))
            try switchProfile(to: availableProfiles[max(0, idx - 1)].id)
        } catch {
            LogManager.shared.appendLog("Profile Error:", error)
        }
    }

    private func setActiveFlag(for id: UUID, to value: Bool) throws {
        guard var prefs = try loadSettings(from: id) else { return }
        prefs.profile.isActive = value
        try savePreferences(prefs, to: settingsURL(for: id))
    }

    private func generateProfileName() -> String {
        let usedNames = Set(availableProfiles.map { $0.name })
        var name = "New Profile"
        var x = 1

        while usedNames.contains(name) {
            name = "New Profile \(x)"
            x += 1
        }

        return name
    }

    enum ProfileError: Error {
        case notFound
        case alreadyExists
        case cannotDeleteOnlyProfile
    }
}
