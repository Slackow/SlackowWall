//
// Created by Kihron on 1/28/23.
//

/*
 For Macro Makers and Verifiers
 The State File is created while the game is running and can be found in .minecraft/wpstateout.txt. The file contains a single line of text containing information about the game's current state, and overwrites itself whenever the state changes. The following states will appear as lines in the file:
 
 waiting                                      | w  119 0x77
 inworld,paused                               | s  115 0x73
 inworld,unpaused                             | a  97  0x61
 inworld,gamescreenopen                       | e  101 0x65
 title                                        | t  116 0x74
 generating,[percent] (before preview starts) | g  103 0x67
 previewing,[percent]                         | p  112 0x70
 */

import SwiftUI

class InstanceInfo: CustomStringConvertible {
    var state: UInt8 = "t".utf8.first!
    var prevState: UInt8 = "t".utf8.first!
    var statePath: String {
        return path.isEmpty ? "" : "\(path)/wpstateout.txt"
    }
    var path: String = ""
    var version: String = ""
    var port: UInt16 = 0
    var untilF3: Int = 0
    var checkState: CheckingMode = .NONE
    var pid: pid_t
    var isBoundless: Bool {
        return port > 3
    }
    var notCheckingBoundless: Bool {
        return port > 3 || port == 0
    }
    
    init (pid: pid_t) {
        self.pid = pid
    }
    
    // for any world preview state output, this will map it to a unique byte and store it into state.
    @discardableResult func updateState(force: Bool = false) -> Bool {
        LogManager.shared.appendLog("Attempting to update instance state...")
        
        // Skip updating state if not forced and checkState is .NONE
        guard force || checkState != .NONE else {
            return false
        }
        
        // Update previous state
        prevState = state
        
        // Attempt to read file data
        guard let fileData = FileManager.default.contents(atPath: statePath), !fileData.isEmpty else {
            print("Error: Failed to read file \(statePath)")
            return false
        }
        
        // Update state based on file data
        var newState = fileData[safe: 0]
        if newState == 0x69 && fileData.count >= 12 {
            newState = fileData[11]
        }
        
        state = newState ?? 0
        LogManager.shared.appendLog("Updated State:", state)
        return prevState != state
    }
    
    var description: String {
        "s: \(state) pstate: \(prevState), f3: \(untilF3) mode: \(checkState), p: \(statePath), pid: \(pid)"
    }
}
