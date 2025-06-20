//
//  ModListViewModel.swift
//  SlackowWall
//
//  Created by Kihron on 6/19/25.
//

import SwiftUI
import ZIPFoundation

class ModListViewModel: ObservableObject {
    @Published var mods: [ModInfo] = []
    
    private let iconCache = NSCache<NSString, NSImage>()
    
    init() {
        
    }
    
    func fetchMods() {
        guard let firstInstance = TrackingManager.shared.trackedInstances.first(where: { $0.instanceNumber == 1 }) else {
            print("No instance found with instanceNumber 1.")
            return
        }
        
        let statePath = firstInstance.info.statePath
        let modsDirectory = URL(filePath: statePath).deletingLastPathComponent().appendingPathComponent("mods")
        let fileManager = FileManager.default
        
        do {
            let modFiles = try fileManager.contentsOfDirectory(at: modsDirectory, includingPropertiesForKeys: nil)
            var fetchedMods: [ModInfo] = []
            
            for modFile in modFiles where modFile.pathExtension == "jar" {
                if let modInfo = extractModInfo(fromJarAt: modFile) {
                    fetchedMods.append(modInfo)
                } else {
                    print("Could not extract mod info from: \(modFile.lastPathComponent)")
                }
            }
            
            // Update the Published property with the fetched mods
            DispatchQueue.main.async {
                self.mods = fetchedMods
            }
        } catch {
            print("Error reading mods directory: \(error)")
        }
    }
    
    private func extractModInfo(fromJarAt url: URL) -> ModInfo? {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            let jsonEntry = "fabric.mod.json"
            
            guard let entry = archive[jsonEntry] else {
                print("JSON file not found in JAR.")
                return nil
            }
            
            var jsonData = Data()
            _ = try archive.extract(entry) { data in
                jsonData.append(data)
            }
            
            // Convert data to a string for preprocessing
            if var jsonString = String(data: jsonData, encoding: .utf8) {
                // Fix the description field by escaping newlines
                if let descriptionRange = jsonString.range(of: "\"description\": \"[^\"]+\"", options: .regularExpression) {
                    var descriptionString = String(jsonString[descriptionRange])
                    descriptionString = descriptionString.replacingOccurrences(of: "\n", with: "\\n")
                    jsonString.replaceSubrange(descriptionRange, with: descriptionString)
                }
                // Convert back to data
                jsonData = Data(jsonString.utf8)
            }
            
            let decoder = JSONDecoder()
            var modInfo = try decoder.decode(ModInfo.self, from: jsonData)
            
            cacheIcon(from: archive, iconPath: modInfo.icon, jarURL: url)
            
            modInfo = ModInfo(
                id: modInfo.id,
                version: modInfo.version,
                name: modInfo.name,
                description: modInfo.description,
                authors: modInfo.authors,
                license: modInfo.license,
                icon: modInfo.icon,
                filePath: url
            )
            
            return modInfo
        } catch DecodingError.dataCorrupted(let context) {
            print("Data corrupted: \(context.debugDescription)")
            return nil
        } catch {
            print("Error occurred: \(error)")
            return nil
        }
    }
    
    func getModIcon(for modInfo: ModInfo) -> NSImage? {
        guard let filePath = modInfo.filePath?.path else {
            return nil
        }
        return getImage(forKey: filePath)
    }
    
    private func getImage(forKey key: String) -> NSImage? {
        return iconCache.object(forKey: key as NSString)
    }
    
    private func cacheImage(_ image: NSImage, forKey key: String) {
        iconCache.setObject(image, forKey: key as NSString)
    }
    
    private func cacheIcon(from archive: Archive, iconPath: String?, jarURL: URL) {
        guard let iconPath = iconPath else {
            return
        }
        
        do {
            guard let iconEntry = archive[iconPath] else {
                print("Icon not found in JAR.")
                return
            }
            
            var iconData = Data()
            _ = try archive.extract(iconEntry) { data in
                iconData.append(data)
            }
            
            if let iconImage = NSImage(data: iconData) {
                cacheImage(iconImage, forKey: jarURL.path)
            } else {
                print("Failed to create image from data.")
            }
        } catch {
            print("Failed to extract icon: \(error)")
        }
    }
}
