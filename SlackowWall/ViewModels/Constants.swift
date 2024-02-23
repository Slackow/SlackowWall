//
//  Constants.swift
//  SlackowWall
//
//  Created by Andrew on 8/3/22.
//

import Foundation

final class Utils {
    // https://gist.github.com/swillits/df648e87016772c7f7e5dbed2b345066?permalink_comment_id=3399235
    // https://stackoverflow.com/questions/72443976/how-to-get-arguments-of-nsrunningapplication
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
