//
//  GameSettingsManager.swift
//  SlackowWall
//
//  Created by Andrew on 3/1/24.
//

import SwiftUI


public class GameSettingsManager: ObservableObject {
    static let shared = GameSettingsManager()
    
    private var filePath: URL?
    
    init() {
        let fileManager = FileManager.default
        // Get the Application Support directory for the user's domain.
        guard let appSupportURL = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        
        // It's common to use the bundle identifier to create a subdirectory for your app.
        let appDirectory = appSupportURL
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "SlackowWall")
            .appendingPathComponent("StandardConfigs")
        
        // Ensure the app's directory exists (create it if not).
        do {
            try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            if error.domain != NSCocoaErrorDomain || error.code != NSFileWriteFileExistsError { return }
        } catch { return }
    
        
        filePath = appDirectory.appendingPathComponent("StandardConfigs.json")
    }
}
