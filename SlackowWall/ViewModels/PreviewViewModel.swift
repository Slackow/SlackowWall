//
// Created by Dominic Thompson on 1/18/23.
//

import SwiftUI

class PreviewViewModel: ObservableObject {

    @MainActor func clickInstance(screenRecorder: ScreenRecorder, idx: Int) {
        screenRecorder.capturePreviews[idx]
        let pid = ShortcutManager.shared.instanceIDs[idx]

        let script = "tell application \"System Events\" to set frontmost of the first process whose unix id is \(pid) to true"

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            ShortcutManager.shared.sendKey(key: 0x35, pid: pid)
        } else {
            print("Failed to send apple script")
        }

        print("pressed: \(pid) #(\(idx))")
    }
}
