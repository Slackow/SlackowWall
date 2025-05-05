//
//  KeyDispatcher.swift
//  SlackowWall
//
//  Created by Kihron on 7/21/24.
//

import SwiftUI

class KeyDispatcher {
    private init() {}
    
    // Send F6
    static func sendReset(pid: pid_t) {
        SoundManager.shared.playSound(sound: "reset")
        sendKey(key: .f6, pid: pid)
    }
    
    static func sendF1(pid: pid_t) {
        sendKey(key: .f1, pid: pid)
    }
    
    static func sendF11(pid: pid_t) {
        sendKey(key: .f11, pid: pid)
    }
    
    // Send F3 + ESC
    static func sendF3Esc(pid: pid_t) {
        sendKeyCombo(keys: [.f3, .escape], pid: pid)
        print("\(pid) << f3 esc")
    }
    
    static func sendEscape(pid: pid_t) {
        sendKey(key: .escape, pid: pid)
    }
    
    // Send a single key press
    static func sendKey(key: KeyCode, pid: pid_t) {
        LogManager.shared.appendLog("Sending key \(key) to \(pid)")
        
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }
        guard let kspd = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true) else { return }
        guard let kspu = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false) else { return }
        
        kspd.postToPid(pid)
        kspu.postToPid(pid)
    }
    
    // Send a combination of key presses
    static func sendKeyCombo(keys: [KeyCode], pid: pid_t) {
        guard let src = CGEventSource(stateID: .hidSystemState) else { return }
        
        for key in keys {
            if let event = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true) {
                event.postToPid(pid)
            }
        }
        
        for key in keys.reversed() {
            if let event = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false) {
                event.postToPid(pid)
            }
        }
    }
}
