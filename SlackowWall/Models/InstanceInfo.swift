//
// Created by Dominic Thompson on 1/28/23.
//


/*
 For Macro Makers and Verifiers
 The State File is created while the game is running and can be found in .minecraft/wpstateout.txt. The file contains a single line of text containing information about the game's current state, and overwrites itself whenever the state changes. The following states will appear as lines in the file:

 waiting                                      | w
 inworld,paused                               | s
 inworld,unpaused                             | a
 inworld,gamescreenopen                       | e
 title                                        | t
 generating,[percent] (before preview starts) | g
 previewing,[percent]                         | p
 */

import SwiftUI

class InstanceInfo: CustomStringConvertible {
    var state: UInt8 = 0
    var prevState: UInt8 = "t".utf8.first!
    var statePath: String = ""
    var untilF3: Int = 0
    var checkState: CheckingMode = .NONE
    var pid: pid_t

    init (pid: pid_t) {
        self.pid = pid
    }
    // for any world preview state output, this will map it to a unique byte and store it into state.
    func updateState() -> Bool {
        prevState = state
        if checkState != .NONE {
            return false
        }
        // Read the file into a data object
        if let fileData = FileManager.default.contents(atPath: statePath) {
            // Read the first byte of the file
            var newState = fileData[0]

            // Check if the first byte is 'i'
            if newState == 0x69 && fileData.count >= 12 {
                // Read the twelfth byte of the file
                newState = fileData[11]
            }
            state = newState
        } else {
            print("Error: Failed to read file \(statePath)")
        }
        return prevState != state
    }

    var description: String {
        "s: \(state), p: \(statePath), pid: \(pid)"
    }
}

enum CheckingMode {
    case NONE, GENNING, ENSURING
}