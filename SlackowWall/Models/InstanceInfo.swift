//
// Created by Dominic Thompson on 1/28/23.
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
        if checkState == .NONE {
            return false
        }
        // Read the file into a data object
        if let fileData = FileManager.default.contents(atPath: statePath), !fileData.isEmpty {
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
        "s: \(state) pstate: \(prevState), f3: \(untilF3) mode: \(checkState), p: \(statePath), pid: \(pid)"
    }
    

}
public let WAITING: UInt8 = 0x77
public let PAUSED: UInt8 = 0x73
public let UNPAUSED: UInt8 = 0x61
public let IN_GAME_SCREEN: UInt8 = 0x65
public let TITLE: UInt8 = 0x74
public let GENERATING: UInt8 = 0x67
public let PREVIEWING: UInt8 = 0x70

enum CheckingMode {
    case NONE, GENNING, ENSURING
}
