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
        if !acted && false {
            acted = true;
            let obs = URL(filePath: "~/Library/Application Support/obs-studio/basic/scenes/Untitled.json", relativeTo: FileManager.default.homeDirectoryForCurrentUser)
            let num = info.count
            let wallSceneName = "wall\(num)"
            var wallScene: NSDictionary? = nil
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
                            } else if name == wallSceneName {
                                wallScene = source
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
                        ] as [String:Any]
                        sources.add(source)
                    }
                    if wallScene == nil {
                        let newSources = NSMutableArray(capacity: num)
                        for i in 0..<num {
                            newSources[i] = [
                                "align": 5,
                                "blend_method": "default",
                                "blend_type": "normal",
                                "bounds": [
                                    "x": 1080,
                                    "y": 920
                                ],
                                "bounds_align": 0,
                                "bounds_type": 1,
                                "crop_bottom": 0,
                                "crop_left": 0,
                                "crop_right": 0,
                                "crop_top": 0,
                                "group_item_backup": false,
                                "hide_transition": [
                                    "duration": 0
                                ],
                                "id": i + 1,
                                "locked": true,
                                "name": "minecraft\(i + 1)",
                                "pos": [
                                    "x": 0,
                                    "y": 0
                                ],
                                "private_settings": [:],
                                "rot": 0,
                                "scale": [
                                    "x": 1,
                                    "y": 1
                                ],
                                "scale_filter": "disable",
                                "show_transition": [
                                    "duration": 0
                                ],
                                "visible": true
                            ]
                        }
                        let scene = [
                            "balance": 0.5,
                            "deinterlace_field_order": 0,
                            "deinterlace_mode": 0,
                            "enabled": true,
                            "flags": 0,
                            "hotkeys": [
                                "libobs.hide_scene_item.about": [],
                                "libobs.show_scene_item.about": [],
                                "OBSBasic.SelectScene": []
                            ],
                            "id": "scene",
                            "mixers": 0,
                            "monitoring_type": 0,
                            "muted": false,
                            "name": wallSceneName,
                            "prev_ver": 486539264,
                            "private_settings": [:],
                            "push-to-mute": false,
                            "push-to-mute-delay": 0,
                            "push-to-talk": false,
                            "push-to-talk-delay": 0,
                            "settings": [
                                "custom_size": false,
                                "id_counter": num,
                                "items": newSources
                            ],
                            "sync": 0,
                            "versioned_id": "scene",
                            "volume": 1
                        ] as [String: Any]
                        sources.add(scene)
                    }


                    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
                    try jsonData.write(to: obs)
                }
            } catch {
                print (error.localizedDescription)
                return
            }
        }
    }
}
