//
// Created by Andrew on 1/23/23.
//

import SwiftUI

class OBSManager: ObservableObject {
    @AppStorage("obsScriptPath") var obsScriptPath = "/tmp/slackowwall.txt"
    
    static let shared = OBSManager()
    
    init() {
        
    }
    
    func writeScript() {
        guard let src = Bundle.main.url(forResource: "instance_selector", withExtension: "lua") else { return }
        
        // Fetch the Application Support directory for the application
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("SlackowWall") else { return }
        
        // Create the directories if they don't exist
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: appSupportURL.appendingPathComponent("Icons"), withIntermediateDirectories: true)
        
        let dst = appSupportURL.appendingPathComponent("instance_selector.lua")
        
        // Remove the existing file if it exists
        try? fileManager.removeItem(at: dst)
        print("does file exist?", fileManager.fileExists(atPath: dst.path))
        
        // Copy the file from the bundle to the Application Support directory
        do {
            try fileManager.copyItem(at: src, to: dst)
            LogManager.shared.appendLog("Wrote script successfully")
        } catch {
            LogManager.shared.appendLog("Error Writing Script:", error.localizedDescription)
        }
    }
    
    func openScriptLocation() {
        do {
            let path = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let appPath = path.appendingPathComponent("SlackowWall")
            NSWorkspace.shared.open(appPath)
        } catch {
            print("Failed to open script path: \(error.localizedDescription)")
        }
    }
    
    func copyScriptToClipboard() {
        let pasteboard = NSPasteboard.general
        let url = getScriptPath()?.path(percentEncoded: false) ?? "~/Library/Application Support/SlackowWall/instance_selector.lua"
        pasteboard.clearContents()
        pasteboard.setString(url, forType: .string)
    }
      
    private func getScriptPath() -> URL? {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SlackowWall") else { return nil }
        return appSupportURL.appendingPathComponent("instance_selector.lua")
    }
    
    @discardableResult func writeWID(windowID: CGWindowID) -> CGWindowID {
        let filePath = obsScriptPath
        let fileContents = "\(UUID()):\(windowID)"
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: filePath) {
            let success = fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
            if !success {
                print("Failed to create file at path: \(filePath)")
            }
        }
        
        do {
            try fileContents.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Error writing to file: \(error)")
        }
        return windowID
    }
}
