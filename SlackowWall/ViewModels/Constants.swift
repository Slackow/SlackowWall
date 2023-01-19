//
//  Constants.swift
//  SlackowWall
//
//  Created by Andrew on 8/3/22.
//

import Foundation
import KeyboardShortcuts
import CloudKit

extension KeyboardShortcuts.Name {
    static let reset = Self("Reset (In Instance)", default: .init(.f7, modifiers: []))
    static let planar = Self("Widen Instance", default: .init(.f8, modifiers: []))
}

final class Utils {
    //https://stackoverflow.com/questions/72443976/how-to-get-arguments-of-nsrunningapplication
    static func processArguments(pid: pid_t) -> [String]? {
        
        // Determine space for arguments:
        var name : [CInt] = [ CTL_KERN, KERN_PROCARGS2, pid ]
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
        var argc : CInt = 0
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
}
extension Dictionary where Value : Hashable {

    func swapKeyValues() -> [Value : Key] {
        var newDict = [Value : Key]()
        for (key, value) in self {
            newDict[value] = key
        }
        return newDict
    }
}

func runScript(myAppleScript: String) -> NSAppleEventDescriptor {
    var error: NSDictionary?
    let scriptObject = NSAppleScript(source: myAppleScript)
    return scriptObject!.executeAndReturnError(&error)
}
