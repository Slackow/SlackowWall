//
// Created by Andrew on 1/23/23.
//

import Foundation
import SwiftUI

class OBSManager {

    static let shared = OBSManager()

    private var acted = false;

    func actOnOBS(info: [(String, CGWindowID)]) {
        var info = info
        if !acted {
            acted = true;
            let obs = URL(filePath: "/Users/andrew/Library/Application Support/obs-studio/basic/scenes/Untitled.json")
            do {
                let data = try Data(contentsOf: obs)
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
                if let jsonDict = jsonObject as? NSDictionary, let sources = jsonDict["sources"] as? NSMutableArray {
                    for source in sources {
                        if let source = source as? NSDictionary {
                            guard let name = source["name"] as? String else { continue }
                            if let window = (info.first { $0.0 == name }) {
                                (source["settings"] as? NSMutableDictionary)?["window"] = window.1
                                info.removeAll(where: {$0 == window})
                            }
                        }
                    }
                    for (name, winID) in info {
                        let source = [
                            "name": name,
                            "settings": ["type": 1, "window": winID],
                            "id": "screen_capture",
                            "prev_ver": 486539264,
                            "private_settings": [:],
                            "push-to-mute": false,
                            "push-to-mute-delay": 0,
                            "push-to-talk": false,
                            "push-to-talk-delay": 0,
                            "mixers": 255,
                            "monitoring_type": 0,
                            "muted": false,
                            "sync": 0,
                            "versioned_id": "screen_capture",
                            "volume": 1,
                            "balance": 0.5,
                            "deinterlace_field_order": 0,
                            "deinterlace_mode": 0,
                            "enabled": true,
                            "flags": 0,
                            "hotkeys": [
                                "libobs.mute": [],
                                "libobs.push-to-mute": [],
                                "libobs.push-to-talk": [],
                                "libobs.unmute": []
                            ]
                        ] as [String: Any]
                        sources.add(source)
                    }
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
                    try jsonData.write(to: obs)
                }
            } catch {
                print (error.localizedDescription)
                return
            }
        }
    }
}
