//
// Created by Andrew on 1/23/23.
//

import SwiftUI

class OBSManager: ObservableObject {
    @AppStorage("obsScriptPath") var obsScriptPath = "/Users/Shared/slackowwall.txt"
    
    static let shared = OBSManager()
    
    var acted = false
    private var wids: [Int:CGWindowID] = [:]
    
    init() {
        
    }
    
    func storeWindowIDs(info: [(Int, CGWindowID)]) {
        if acted { return }
        acted = true
        for (key, wid) in info {
            wids[key] = wid
        }
        print("Hey I stored the window ID's: \(wids)")
    }
    
    func writeWID(idx: Int) -> CGWindowID {
        let filePath = obsScriptPath
        let wid = wids[idx] ?? 0
        let fileContents = "\(UUID()):\(wid)"
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
        return wid
    }
}
