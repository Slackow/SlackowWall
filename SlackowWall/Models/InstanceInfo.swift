//
// Created by Dominic Thompson on 1/28/23.
//

import SwiftUI

class InstanceInfo: CustomStringConvertible {
    var state: InstanceState = .INIT
    var logPath: String = ""
    var logRead: UInt64 = 0
    var onNextF3: Bool = false
    var pid: pid_t

    init (pid: pid_t) {
        self.pid = pid
    }

    var description: String {
        "s: \(state), p: \(logPath), r: \(logRead), pid: \(pid)"
    }
}