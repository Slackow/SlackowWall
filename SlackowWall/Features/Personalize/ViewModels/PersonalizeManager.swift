//
//  PersonalizeManager.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

class PersonalizeManager: ObservableObject {
    @Published var lockIcons = [UserLock]()

    private let fileManager = FileManager.default

    static let shared: PersonalizeManager = .init()

    init() {
        loadLockIcons()
    }

    var selectedUserLock: UserLock? {
        return lockIcons.first(where: { $0.icon == Settings[\.personalize].selectedUserLock?.icon })
    }

    func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .jpeg]

        if panel.runModal() == .OK, let url = panel.url {
            saveImage(url: url)
            loadLockIcons()
        }
    }

    private func saveImage(url: URL) {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)

        let uuid = UUID().uuidString
        let fileExtension = url.pathExtension
        let destinationFileName = "\(uuid).\(fileExtension)"

        let destinationURL = baseURL.appendingPathComponent(destinationFileName)

        do {
            try fileManager.copyItem(at: url, to: destinationURL)
            try fileManager.setAttributes(
                [.creationDate: Date.now], ofItemAtPath: destinationURL.path)
        } catch {
            print("Failed to copy image: \(error.localizedDescription)")
        }
    }

    private func loadLockIcons() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: baseURL, includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles)

            let sortedFileURLs = fileURLs.sorted { (url1, url2) -> Bool in
                let creationDate1 = try? url1.resourceValues(forKeys: [.creationDateKey])
                    .creationDate
                let creationDate2 = try? url2.resourceValues(forKeys: [.creationDateKey])
                    .creationDate
                return (creationDate1 ?? Date.distantPast) < (creationDate2 ?? Date.distantPast)
            }

            lockIcons = sortedFileURLs.compactMap { url in
                guard let image = NSImage(contentsOf: url) else { return nil }
                let imageName = url.deletingPathExtension().lastPathComponent
                image.setName(imageName)
                return UserLock(id: UUID(), icon: url.lastPathComponent)
            }

            LogManager.shared.appendLog("[Asset]: Loaded \(lockIcons.count) lock icons.")
        } catch {
            print("Failed to load images: \(error.localizedDescription)")
        }
    }

    func deleteLockIcon(userLock: UserLock) {
        do {
            let iconPath = baseURL.appendingPathComponent(userLock.icon)
            try fileManager.removeItem(at: iconPath)

            withAnimation(.easeInOut) {
                if let idx = lockIcons.firstIndex(where: { $0 == userLock }) {
                    if userLock == selectedUserLock {
                        if idx - 1 >= 0 {
                            selectUserLockIcon(userLock: lockIcons[idx - 1])
                        } else {
                            selectLockPreset(preset: .apple)
                        }
                    }

                    lockIcons.remove(at: idx)
                }
            }
        } catch {
            print("Failed to delete lock icon: \(error.localizedDescription)")
        }
    }

    func selectLockPreset(preset: LockPreset) {
        Settings[\.personalize].lockMode = .preset
        Settings[\.personalize].selectedLockPreset = preset
        Settings[\.personalize].selectedUserLock = nil
    }

    func selectUserLockIcon(userLock: UserLock) {
        Settings[\.personalize].lockMode = .custom
        Settings[\.personalize].selectedUserLock = userLock
    }

    private var baseURL: URL {
        fileManager
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/SlackowWall", isDirectory: true)
            .appendingPathComponent("Icons", isDirectory: true)
    }
}
