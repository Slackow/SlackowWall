//
//  ModChecking.swift
//  SlackowWall
//
//  Created by Andrew on 9/27/25.
//

import Foundation
import DefaultCodable

final class ModChecking {

    private static let schema = URL(string: "https://raw.githubusercontent.com/tildejustin/mcsr-meta/schema-6/mods.json");

    private static func getLegalMods() async throws -> [ModSchema] {
        if let _legalMods { return _legalMods }
        guard let schema else { return [] }
        let req = URLRequest(url: schema, timeoutInterval: 2)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse,
            200..<300 ~= http.statusCode
        else { return [] }
        let json = try JSONDecoder().decode(FullModSchema.self, from: data)
        _legalMods = json.mods
        return json.mods
    }

    private static var _legalMods: [ModSchema]?

    static func modsToUpdate(info: InstanceInfo) async throws -> ([(ModInfo, ModVersion)], Int) {
        let mcVersion = info.version
        let legalMods = try await getLegalMods()
        return (info.mods.compactMap { mod in
            if mod.disabled == true { return nil }
            let legalSchema = legalMods.first { $0.modid == mod.id }
            guard let latestVersion = legalSchema?.getModVersion(for: mcVersion) else {
                LogManager.shared.appendLog("Skipping non-legal mod:", mod.id, mod.version)
                return nil
            }
            if latestVersion.version == mod.version {
                LogManager.shared.appendLog("Up to date:", mod.id, mod.version)
                return nil
            }
            LogManager.shared.appendLog("The latest version for", mod.id, "is", latestVersion.version, "and you have", mod.version)
            return (mod, latestVersion)
        }, info.mods.filter{legalMods.map(\.modid).contains($0.id)}.count)
    }
    
    @discardableResult
    static func updateMods(
      instance: TrackedInstance,
      mods: [(ModInfo, ModVersion)]
    ) async -> ([(ModInfo, ModVersion)], [(ModInfo, ModVersion)]) {
      guard !mods.isEmpty else { return ([], mods) }
      LogManager.shared.appendLog(
        "is terminated:",
        TrackingManager.shared.kill(instance: instance)?.isTerminated ?? true
      )

      return await withTaskGroup(of: (ModInfo, ModVersion, Bool).self) { group in
        for (info, version) in mods {
          group.addTask {
            do {
              try await updateMod(info: info, version: version)
              return (info, version, true)
            } catch {
              LogManager.shared.appendLog(
                "Failed to update mod \"\(info.id)\", \"\(info.version)\": \(error)"
              )
              return (info, version, false)
            }
          }
        }

        var succeeded: [(ModInfo, ModVersion)] = []
        var failed: [(ModInfo, ModVersion)] = []

        for await (info, version, ok) in group {
          if ok { succeeded.append((info, version)) }
          else { failed.append((info, version)) }
        }
        return (succeeded, failed)
      }
    }

    static func updateMod(info: ModInfo, version: ModVersion) async throws {
        guard let modPath = info.filePath,
            let url = URL(string: version.url) else { return }
        let urlRequest = URLRequest(url: url, timeoutInterval: 2)
        let (jar, response) = try await URLSession.shared.data(for: urlRequest)
        guard let response = response as? HTTPURLResponse,
            200..<300 ~= response.statusCode else { return }
        let destination = modPath.deletingLastPathComponent()
            .appending(path: URL(filePath: version.url).lastPathComponent)
        print("here", destination)
        try jar.write(to: destination)
        if destination.lastPathComponent != modPath.lastPathComponent {
            try FileManager.default.removeItem(at: modPath)
        }
    }

}

struct FullModSchema: Codable {
    let schemaVersion: Int
    let mods: [ModSchema]
}

@DefaultCodable
struct ModSchema: Codable {
    let modid: String
    let name: String
    let description: String
    let sources: String
    let versions: [ModVersion]
    var traits: [String] = []
    var incompatibilities: [String] = []
    var recommended: Bool = true
    var obsolete: Bool = false
}

// sort, !obselete -> recommended -> mac-only

extension ModSchema {
    func suggestForVersion(version: String, ssg: Bool) -> Bool {
        if self.obsolete { return false }
        if traits.contains(ssg ? "rsg-only" : "ssg-only") { return false }
        if let modVersion = getModVersion(for: version) {
            return !modVersion.obsolete
        }
        return false
    }

    func getModVersion(for version: String) -> ModVersion? {
        versions.first { $0.target_version.contains(version) }
    }

    var macOnly: Bool {
        traits.contains("mac-only")
    }
}

@DefaultCodable
struct ModVersion: Codable {
    let target_version: [String]
    let version: String
    let url: String
    let hash: String
    var recommended: Bool = true
    var obsolete: Bool = false
}

