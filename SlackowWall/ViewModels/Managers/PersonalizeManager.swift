//
//  PersonalizeManager.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

class PersonalizeManager: ObservableObject {
    @Published var lockIcons = [UserLock]()
    
    private let iconFolderPath = "SlackowWall/Icons/"
    
    static let shared = PersonalizeManager()
    
    var selectedUserLock: UserLock? {
        return lockIcons.first(where: { $0.icon == ProfileManager.shared.profile.selectedUserLock?.icon })
    }
    
    init() {
        loadLockIcons()
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
        let fileManager = FileManager.default
        guard let appDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let iconsFolder = appDirectory.appendingPathComponent(iconFolderPath)
        try? fileManager.createDirectory(at: iconsFolder, withIntermediateDirectories: true)
        
        let uuid = UUID().uuidString
        let fileExtension = url.pathExtension
        let destinationFileName = "\(uuid).\(fileExtension)"
        
        let destinationURL = iconsFolder.appendingPathComponent(destinationFileName)
        
        do {
            try fileManager.copyItem(at: url, to: destinationURL)
            try fileManager.setAttributes([.creationDate: Date.now], ofItemAtPath: destinationURL.path)
        } catch {
            print("Failed to copy image: \(error.localizedDescription)")
        }
    }
    
    private func loadLockIcons() {
        let fileManager = FileManager.default
        guard let appDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let iconsFolder = appDirectory.appendingPathComponent(iconFolderPath)
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: iconsFolder, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            let sortedFileURLs = fileURLs.sorted { (url1, url2) -> Bool in
                let creationDate1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
                let creationDate2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
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
        let fileManager = FileManager.default
        guard let appDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let iconPath = appDirectory.appendingPathComponent(iconFolderPath).appendingPathComponent(userLock.icon)
        
        do {
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
        ProfileManager.shared.profile.lockMode = .preset
        ProfileManager.shared.profile.selectedLockPreset = preset
        ProfileManager.shared.profile.selectedUserLock = nil
    }
    
    func selectUserLockIcon(userLock: UserLock) {
        ProfileManager.shared.profile.lockMode = .custom
        ProfileManager.shared.profile.selectedUserLock = userLock
    }
}

enum LockMode: String {
    case preset, custom
}
