//
//  KeybindingManager.swift
//  SlackowWall
//
//  Created by Andrew on 2/23/24.
//

import SwiftUI

class KeybindingManager: ObservableObject {
    @AppStorage("resetGKey")      var resetGKey:      KeyCode? = .keypad0
    @AppStorage("resetAllKey")    var resetAllKey:    KeyCode? = .t
    @AppStorage("resetOthersKey") var resetOthersKey: KeyCode? = .f
    @AppStorage("runKey")         var runKey:         KeyCode? = .r
    @AppStorage("resetOneKey")    var resetOneKey:    KeyCode? = .e
    @AppStorage("lockKey")        var lockKey:        KeyCode? = .c
    
    static let shared = KeybindingManager()
    
    init() {}
    
    func handleGlobalKey(_ key: NSEvent) {
        if resetGKey == key.keyCode {
            ShortcutManager.shared.globalReset()
        }
    }
}

typealias KeyCode = UInt16

extension KeyCode {
    
    // Layout-independent Keys
    // eg.These key codes are always the same key on all layouts.
    static let returnKey                 : KeyCode = 0x24
    static let enter                     : KeyCode = 0x4C
    static let tab                       : KeyCode = 0x30
    static let space                     : KeyCode = 0x31
    static let delete                    : KeyCode = 0x33
    static let escape                    : KeyCode = 0x35
    static let command                   : KeyCode = 0x37
    static let shift                     : KeyCode = 0x38
    static let capsLock                  : KeyCode = 0x39
    static let option                    : KeyCode = 0x3A
    static let control                   : KeyCode = 0x3B
    static let rightCommand              : KeyCode = 0x36
    static let rightShift                : KeyCode = 0x3C
    static let rightOption               : KeyCode = 0x3D
    static let rightControl              : KeyCode = 0x3E
    static let leftArrow                 : KeyCode = 0x7B
    static let rightArrow                : KeyCode = 0x7C
    static let downArrow                 : KeyCode = 0x7D
    static let upArrow                   : KeyCode = 0x7E
    static let volumeUp                  : KeyCode = 0x48
    static let volumeDown                : KeyCode = 0x49
    static let mute                      : KeyCode = 0x4A
    static let help                      : KeyCode = 0x72
    static let home                      : KeyCode = 0x73
    static let pageUp                    : KeyCode = 0x74
    static let forwardDelete             : KeyCode = 0x75
    static let end                       : KeyCode = 0x77
    static let pageDown                  : KeyCode = 0x79
    static let function                  : KeyCode = 0x3F
    static let f1                        : KeyCode = 0x7A
    static let f2                        : KeyCode = 0x78
    static let f4                        : KeyCode = 0x76
    static let f5                        : KeyCode = 0x60
    static let f6                        : KeyCode = 0x61
    static let f7                        : KeyCode = 0x62
    static let f3                        : KeyCode = 0x63
    static let f8                        : KeyCode = 0x64
    static let f9                        : KeyCode = 0x65
    static let f10                       : KeyCode = 0x6D
    static let f11                       : KeyCode = 0x67
    static let f12                       : KeyCode = 0x6F
    static let f13                       : KeyCode = 0x69
    static let f14                       : KeyCode = 0x6B
    static let f15                       : KeyCode = 0x71
    static let f16                       : KeyCode = 0x6A
    static let f17                       : KeyCode = 0x40
    static let f18                       : KeyCode = 0x4F
    static let f19                       : KeyCode = 0x50
    static let f20                       : KeyCode = 0x5A
    
    // US-ANSI Keyboard Positions
    // eg. These key codes are for the physical key (in any keyboard layout)
    // at the location of the named key in the US-ANSI layout.
    static let a                         : KeyCode = 0x00
    static let b                         : KeyCode = 0x0B
    static let c                         : KeyCode = 0x08
    static let d                         : KeyCode = 0x02
    static let e                         : KeyCode = 0x0E
    static let f                         : KeyCode = 0x03
    static let g                         : KeyCode = 0x05
    static let h                         : KeyCode = 0x04
    static let i                         : KeyCode = 0x22
    static let j                         : KeyCode = 0x26
    static let k                         : KeyCode = 0x28
    static let l                         : KeyCode = 0x25
    static let m                         : KeyCode = 0x2E
    static let n                         : KeyCode = 0x2D
    static let o                         : KeyCode = 0x1F
    static let p                         : KeyCode = 0x23
    static let q                         : KeyCode = 0x0C
    static let r                         : KeyCode = 0x0F
    static let s                         : KeyCode = 0x01
    static let t                         : KeyCode = 0x11
    static let u                         : KeyCode = 0x20
    static let v                         : KeyCode = 0x09
    static let w                         : KeyCode = 0x0D
    static let x                         : KeyCode = 0x07
    static let y                         : KeyCode = 0x10
    static let z                         : KeyCode = 0x06
    
    static let zero                      : KeyCode = 0x1D
    static let one                       : KeyCode = 0x12
    static let two                       : KeyCode = 0x13
    static let three                     : KeyCode = 0x14
    static let four                      : KeyCode = 0x15
    static let five                      : KeyCode = 0x17
    static let six                       : KeyCode = 0x16
    static let seven                     : KeyCode = 0x1A
    static let eight                     : KeyCode = 0x1C
    static let nine                      : KeyCode = 0x19
    
    static let equals                    : KeyCode = 0x18
    static let minus                     : KeyCode = 0x1B
    static let semicolon                 : KeyCode = 0x29
    static let apostrophe                : KeyCode = 0x27
    static let comma                     : KeyCode = 0x2B
    static let period                    : KeyCode = 0x2F
    static let forwardSlash              : KeyCode = 0x2C
    static let backslash                 : KeyCode = 0x2A
    static let grave                     : KeyCode = 0x32
    static let leftBracket               : KeyCode = 0x21
    static let rightBracket              : KeyCode = 0x1E
    
    static let keypadDecimal             : KeyCode = 0x41
    static let keypadMultiply            : KeyCode = 0x43
    static let keypadPlus                : KeyCode = 0x45
    static let keypadClear               : KeyCode = 0x47
    static let keypadDivide              : KeyCode = 0x4B
    static let keypadEnter               : KeyCode = 0x4C
    static let keypadMinus               : KeyCode = 0x4E
    static let keypadEquals              : KeyCode = 0x51
    static let keypad0                   : KeyCode = 0x52
    static let keypad1                   : KeyCode = 0x53
    static let keypad2                   : KeyCode = 0x54
    static let keypad3                   : KeyCode = 0x55
    static let keypad4                   : KeyCode = 0x56
    static let keypad5                   : KeyCode = 0x57
    static let keypad6                   : KeyCode = 0x58
    static let keypad7                   : KeyCode = 0x59
    static let keypad8                   : KeyCode = 0x5B
    static let keypad9                   : KeyCode = 0x5C
    
    private static let nameDict: [KeyCode:String] = [
        0x24: "Return",
        0x30: "Tab",
        0x31: "Space",
        0x33: "Backspace",
        0x35: "Escape",
        0x37: "Command",
        0x38: "Shift",
        0x39: "Caps",
        0x3A: "Option",
        0x3B: "Control",
        0x36: "RCommand",
        0x3C: "RShift",
        0x3D: "ROption",
        0x3E: "RControl",
        0x7B: "Left",
        0x7C: "Right",
        0x7D: "Down",
        0x7E: "Up",
        0x48: "Vol Up",
        0x49: "Vol Dn",
        0x4A: "Mute",
        0x72: "Help",
        0x73: "Home",
        0x74: "Pg Up",
        0x75: "Delete",
        0x77: "End",
        0x79: "Pg Dn",
        0x3F: "Fn",
        0x7A: "F1",
        0x78: "F2",
        0x76: "F4",
        0x60: "F5",
        0x61: "F6",
        0x62: "F7",
        0x63: "F3",
        0x64: "F8",
        0x65: "F9",
        0x6D: "F10",
        0x67: "F11",
        0x6F: "F12",
        0x69: "F13",
        0x6B: "F14",
        0x71: "F15",
        0x6A: "F16",
        0x40: "F17",
        0x4F: "F18",
        0x50: "F19",
        0x5A: "F20",
        0x00: "A",
        0x0B: "B",
        0x08: "C",
        0x02: "D",
        0x0E: "E",
        0x03: "F",
        0x05: "G",
        0x04: "H",
        0x22: "I",
        0x26: "J",
        0x28: "K",
        0x25: "L",
        0x2E: "M",
        0x2D: "N",
        0x1F: "O",
        0x23: "P",
        0x0C: "Q",
        0x0F: "R",
        0x01: "S",
        0x11: "T",
        0x20: "U",
        0x09: "V",
        0x0D: "W",
        0x07: "X",
        0x10: "Y",
        0x06: "Z",
        0x1D: "0",
        0x12: "1",
        0x13: "2",
        0x14: "3",
        0x15: "4",
        0x17: "5",
        0x16: "6",
        0x1A: "7",
        0x1C: "8",
        0x19: "9",
        0x18: "=",
        0x1B: "-",
        0x29: ";",
        0x27: "'",
        0x2B: ",",
        0x2F: ".",
        0x2C: "/",
        0x2A: "\\",
        0x32: "`",
        0x21: "[",
        0x1E: "]",
        0x41: "Num.",
        0x43: "Num*",
        0x45: "Num+",
        0x47: "Clear",
        0x4B: "Num/",
        0x4C: "Enter",
        0x4E: "Minus",
        0x51: "Num=",
        0x52: "Num0",
        0x53: "Num1",
        0x54: "Num2",
        0x55: "Num3",
        0x56: "Num4",
        0x57: "Num5",
        0x58: "Num6",
        0x59: "Num7",
        0x5B: "Num8",
        0x5C: "Num9",
    ]
    
    static func toName(code: KeyCode?) -> String {
        return code.flatMap({nameDict[$0] ?? "Unknown"}) ?? "None"
    }
}
