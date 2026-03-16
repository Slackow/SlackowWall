//
//  Constants.swift
//  SlackowWall
//
//  Created by Andrew on 8/3/22.
//

import Darwin
import Foundation

final class Utilities {
    private init() {}

    // https://gist.github.com/swillits/df648e87016772c7f7e5dbed2b345066?permalink_comment_id=3399235
    // https://stackoverflow.com/questions/72443976/how-to-get-arguments-of-nsrunningapplication
    static func processArguments(pid: pid_t) -> [String]? {

        // Determine space for arguments:
        var name: [CInt] = [CTL_KERN, KERN_PROCARGS2, pid]
        var length: size_t = 0
        if sysctl(&name, CUnsignedInt(name.count), nil, &length, nil, 0) == -1 {
            return nil
        }

        // Get raw arguments:
        var buffer = [CChar](repeating: 0, count: length)
        if sysctl(&name, CUnsignedInt(name.count), &buffer, &length, nil, 0) == -1 {
            return nil
        }

        // There should be at least the space for the argument count:
        var argc: CInt = 0
        if length < MemoryLayout.size(ofValue: argc) {
            return nil
        }

        var argv: [String] = []

        buffer.withUnsafeBufferPointer { bp in

            // Get argc:
            memcpy(&argc, bp.baseAddress, MemoryLayout.size(ofValue: argc))
            var pos = MemoryLayout.size(ofValue: argc)

            // Skip the saved exec_path.
            while pos < bp.count && bp[pos] != 0 {
                pos += 1
            }
            if pos == bp.count {
                return
            }

            // Skip trailing '\0' characters.
            while pos < bp.count && bp[pos] == 0 {
                pos += 1
            }
            if pos == bp.count {
                return
            }

            // Iterate through the '\0'-terminated strings.
            for _ in 0..<argc {
                let start = bp.baseAddress! + pos
                while pos < bp.count && bp[pos] != 0 {
                    pos += 1
                }
                if pos == bp.count {
                    return
                }
                argv.append(String(cString: start))
                pos += 1
            }
        }

        return argv.count == argc ? argv : nil
    }

    enum ProcessEnvError: Error {
        case sysctlFailed(Int32)
        case malformedProcArgs
    }

    static func getEnvironmentValue(pid: pid_t, key: String) throws -> String? {
        let argMax = Int(sysconf(Int32(_SC_ARG_MAX)))
        guard argMax > 0 else {
            throw ProcessEnvError.malformedProcArgs
        }

        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        let mibCount = u_int(mib.count)

        var buffer = [CChar](repeating: 0, count: argMax)
        var size = buffer.count

        let result = sysctl(&mib, mibCount, &buffer, &size, nil, 0)
        guard result == 0 else {
            throw ProcessEnvError.sysctlFailed(errno)
        }

        guard size >= MemoryLayout<Int32>.size else {
            throw ProcessEnvError.malformedProcArgs
        }

        return try buffer.withUnsafeBufferPointer { rawBuf -> String? in
            guard let base = rawBuf.baseAddress else {
                throw ProcessEnvError.malformedProcArgs
            }

            let end = base.advanced(by: size)
            let raw = UnsafeRawPointer(base)

            let argc = raw.load(as: Int32.self)
            guard argc >= 0 else {
                throw ProcessEnvError.malformedProcArgs
            }

            var p = base.advanced(by: MemoryLayout<Int32>.size)

            func skipCString(_ ptr: inout UnsafePointer<CChar>) throws {
                while ptr < end, ptr.pointee != 0 {
                    ptr = ptr.advanced(by: 1)
                }
                guard ptr < end else {
                    throw ProcessEnvError.malformedProcArgs
                }
                ptr = ptr.advanced(by: 1)
            }

            func skipNuls(_ ptr: inout UnsafePointer<CChar>) {
                while ptr < end, ptr.pointee == 0 {
                    ptr = ptr.advanced(by: 1)
                }
            }

            try skipCString(&p)
            skipNuls(&p)

            for _ in 0..<argc {
                try skipCString(&p)
            }

            skipNuls(&p)

            while p < end, p.pointee != 0 {
                let entry = String(cString: p)

                if let eq = entry.firstIndex(of: "=") {
                    let entryKey = String(entry[..<eq])
                    if entryKey == key {
                        return String(entry[entry.index(after: eq)...])
                    }
                }

                try skipCString(&p)
            }

            return nil
        }
    }

    static func hasDYLDInsertLibraries(pid: pid_t) -> Bool {
        (try? getEnvironmentValue(pid: pid, key: "DYLD_INSERT_LIBRARIES")) != nil
    }

}
