//
//  UpdateManager.swift
//  SwiftAA
//
//  Created by Kihron on 8/19/22.
//

import Sparkle
import SwiftUI

// This view model class manages Sparkle's updater and publishes when new updates are allowed to be checked
final class UpdateManager: NSObject, ObservableObject, SPUUpdaterDelegate {
    @AppStorage("checkAutomatically") var checkAutomatically: Bool = true
    @AppStorage("downloadAutomatically") var downloadAutomatically: Bool = true
    @AppStorage("lastAppBuild") var lastAppBuild: String = ""
    @AppStorage("updateChannel") var updateChannel: UpdateChannel = .release

    private lazy var updaterController: SPUStandardUpdaterController = {
        SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }()

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

    override init() {
        super.init()

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
        guard let currentBuild = appBuild else { return }

        if lastAppBuild.isEmpty {
            lastAppBuild = currentBuild
        } else {
            if let lastBuildNumber = Int(lastAppBuild), let currentBuildNumber = Int(currentBuild),
                lastBuildNumber < currentBuildNumber
            {
                appWasUpdated = true
            }
            if lastAppBuild != currentBuild {
                lastAppBuild = currentBuild
            }
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

            // Filter releases with the same minor version
            let filteredReleaseNotes = allReleaseNotes.filter { releaseEntry in
                updateChannel == .beta || releaseEntry.prerelease != true
            }.prefix(5)

            self.releaseNotes = Array(filteredReleaseNotes)
        } catch {
            print(error.localizedDescription)
        }
    }
}
