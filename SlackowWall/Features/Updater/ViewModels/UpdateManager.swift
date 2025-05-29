//
//  UpdateManager.swift
//  SwiftAA
//
//  Created by Kihron on 8/19/22.
//

import Sparkle
import SwiftUI

// This view model class manages Sparkle's updater and publishes when new updates are allowed to be checked
final class UpdateManager: ObservableObject {
    @AppStorage("checkAutomatically") var checkAutomatically: Bool = true
    @AppStorage("downloadAutomatically") var downloadAutomatically: Bool = true
    @AppStorage("lastAppVersion") var lastAppVersion: String = ""

    private let updaterController: SPUStandardUpdaterController

    static let shared = UpdateManager()

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

    @Published private var canCheckForUpdates = false

    @Published var appWasUpdated: Bool = false

    @Published var readyToInstallUpdate: Bool = false

    private var currentReleaseNotes: String = ""
    private var majorReleaseNotes: String = ""

    @Published var releaseNotes: [ReleaseEntry] = []

    var automaticallyCheckForUpdates: Bool {
        get {
            updaterController.updater.automaticallyChecksForUpdates = checkAutomatically
            return checkAutomatically
        }
        set(newValue) {
            updaterController.updater.automaticallyChecksForUpdates = newValue
            checkAutomatically = newValue
        }
    }

    var automaticallyDownloadUpdates: Bool {
        get {
            updaterController.updater.automaticallyDownloadsUpdates = downloadAutomatically
            return downloadAutomatically
        }
        set(newValue) {
            updaterController.updater.automaticallyDownloadsUpdates = newValue
            downloadAutomatically = newValue
        }
    }

    let lastUpdateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)

        let _ = automaticallyDownloadUpdates
        if automaticallyCheckForUpdates {
            updaterController.updater.checkForUpdatesInBackground()
        }

        Task {
            await fetchLatestReleaseNotes()
            await checkForAppUpdated()
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func getLastUpdateCheckDate() -> Date? {
        return updaterController.updater.lastUpdateCheckDate
    }

    @MainActor private func checkForAppUpdated() {
        guard let currentVersion = appVersion else {
            return
        }

        if lastAppVersion.isEmpty {
            lastAppVersion = currentVersion
        } else if lastAppVersion != currentVersion {
            appWasUpdated = true
            lastAppVersion = currentVersion
        }
    }

    @MainActor private func fetchLatestReleaseNotes() async {
        guard
            let url = URL(
                string: "https://api.github.com/repos/Slackow/SlackowWall/releases?per_page=10")
        else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let (data, _) = try await URLSession.shared.data(from: url)
            let allReleaseNotes = try decoder.decode([ReleaseEntry].self, from: data)

            guard let appVersionComponents = appVersion?.split(separator: ".").map(String.init),
                appVersionComponents.count >= 2
            else { return }
            let minorVersion = appVersionComponents[1]

            // Filter releases with the same minor version
            let filteredReleaseNotes = allReleaseNotes.filter { releaseEntry in
                let versionComponents = releaseEntry.tagName.split(separator: ".").map(String.init)
                return versionComponents.count >= 2 && versionComponents[1] == minorVersion
            }

            self.releaseNotes = filteredReleaseNotes
        } catch {
            print(error.localizedDescription)
        }
    }
}
