//
//  Settings.swift
//  SlackowWall
//
//  Created by Kihron on 5/3/25.
//

import Combine
import SwiftUI

final class Settings: ObservableObject {
    private let fileManager = FileManager.default

    nonisolated(unsafe) static let shared: Settings = .init()
    nonisolated(unsafe) var profileCreatedOrDeleted: Bool = false

    // Raw UUID string persisted in UserDefaults.
    @AppStorage("currentProfileRawID") private var currentProfileRawID: String = ""

    // In‑memory UUID that the rest of the app uses.
    @Published var currentProfile: UUID = .init() {
        didSet {
            currentProfileRawID = currentProfile.uuidString  // persist change
            try? switchProfile(to: currentProfile)
            preferences = loadSettings()  // reload profile
        }
    }

    @Published var preferences: Preferences

    private var storeTask: AnyCancellable!

    private init() {
        self.preferences = .init()
        currentProfile = UUID(uuidString: currentProfileRawID) ?? preferences.profile.id
        currentProfileRawID = currentProfile.uuidString
        if currentProfile != preferences.profile.id {
            LogManager.shared.appendLog(
                "These should match, and they do not.", currentProfileRawID, preferences.profile.id)
        }
        observePreferences()
    }

    private func observePreferences() {
        self.storeTask = self.$preferences.sink {
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
        let currentProfile = self.currentProfile
        let url = settingsURL(for: currentProfile)
        LogManager.shared.appendLog("Active Profile:", currentProfile, preferences.profile.name)

        guard fileManager.fileExists(atPath: url.path),
            let json = try? Data(contentsOf: url),
            let prefs = try? JSONDecoder().decode(Preferences.self, from: json)
        else {
            try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: false)
            try? availableProfiles.filter { $0.name == "Main" }.map(\.id).map(settingsURL).forEach(
                fileManager.removeItem(at:))
            var prefs = Preferences()
            prefs.profile.id = currentProfile
            return prefs
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
        try savePreferences(prefs, to: settingsURL(for: prefs.profile.id))
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
            .appending(path: "Library/Application Support/SlackowWall/")
            .appending(path: "Profiles/")
    }

    private func settingsURL(for id: UUID) -> URL {
        baseURL
            .appending(path: id.uuidString)
            .appendingPathExtension("json")
    }

    func autoSwitch() {
        let preferences = Settings.shared.availableProfiles
            .compactMap { try? loadSettings(from: $0.id) }
        for pref in preferences {
            if let monWidth = pref.profile.expectedMWidth,
                let monHeight = pref.profile.expectedMHeight,
                let frame = NSScreen.main?.frame,
                Int(frame.width) == monWidth, Int(frame.height) == monHeight,
                self.preferences.profile.id != pref.profile.id
            {
                try? switchProfile(to: pref.profile.id)
                LogManager.shared.appendLog("Auto switched profiles")
                return
            }
        }
    }
}

extension Settings {
    var availableProfiles: [(id: UUID, name: String)] {
        return (try? fileManager.contentsOfDirectory(atPath: baseURL.path))?
            .compactMap { filename in
                guard filename.hasSuffix(".json"),
                    let id = UUID(uuidString: (filename as NSString).deletingPathExtension),
                    let prefs = try? loadSettings(from: id)
                else { return nil }
                return (id, prefs.profile.name)
            } ?? []
    }

    func createProfile() {
        guard availableProfiles.count < 10 else { return }
        var prefs = preferences
        prefs.profile.id = UUID()
        prefs.profile.name = generateProfileName()

        do {
            let url = settingsURL(for: prefs.profile.id)
            guard !fileManager.fileExists(atPath: url.path) else {
                throw ProfileError.alreadyExists
            }

            try savePreferences(prefs, to: url)
            try switchProfile(to: prefs.profile.id)
        } catch {
            LogManager.shared.appendLog("Profile Error:", error)
        }
        profileCreatedOrDeleted = true
        TrackingManager.shared.trackedInstances.forEach({ $0.stream.clearCapture() })
    }

    func switchProfile(to id: UUID) throws {
        guard id != currentProfile else { return }
        guard availableProfiles.map(\.id).contains(id) else { throw ProfileError.notFound }
        try savePreferences(preferences, to: settingsURL(for: currentProfile))
        guard let prefs = try loadSettings(from: id) else { throw ProfileError.notFound }
        preferences = prefs
        currentProfile = id
    }

    func deleteCurrentProfile() {
        do {
            let profiles = availableProfiles
            guard profiles.count > 1 else { throw ProfileError.cannotDeleteOnlyProfile }
            guard let idx = profiles.firstIndex(where: { $0.id == currentProfile }) else {
                throw ProfileError.notFound
            }

            LogManager.shared.logPath("Deleting: \(settingsURL(for: currentProfile))")
            let id = currentProfile
            try switchProfile(to: profiles[(idx + profiles.count - 1) % profiles.count].id)
            try fileManager.removeItem(at: settingsURL(for: id))
        } catch {
            LogManager.shared.appendLog("Profile Error:", error)
        }
        profileCreatedOrDeleted = true
        TrackingManager.shared.trackedInstances.forEach({ $0.stream.clearCapture() })
    }

    private func generateProfileName() -> String {
        let usedNames = Set(availableProfiles.map(\.name))
        let currentName = preferences.profile.name
        let baseName = currentName.replacing(/\s\d+$/, with: "")
        var name = baseName
        var x = 2
        while usedNames.contains(name) {
            name = "\(baseName) \(x)"
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
