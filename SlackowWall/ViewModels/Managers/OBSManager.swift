//
// Created by Andrew on 1/23/23.
//

import Foundation
import SwiftUI

class OBSManager {

    static let shared = OBSManager()
    
    @AppStorage("obsScriptPath")
    public var obsScriptPath = "/Users/Shared/slackowwall.txt"

    public var acted = false
    private var wids: [Int:CGWindowID] = [:]

    func storeWindowIDs(info: [(Int, CGWindowID)]) {
        if acted { return }
        acted = true
        for (key, wid) in info {
            wids[key] = wid
        }
        print("Hey I stored the window ID's: \(wids)")
    }
    
    public func writeWID(idx: Int) -> CGWindowID {
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
