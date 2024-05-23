//
//  AlertManager.swift
//  SlackowWall
//
//  Created by Kihron on 5/21/24.
//

import SwiftUI

class AlertManager: ObservableObject {
    @Published var alert: WallAlert? = .none
    
    static let shared = AlertManager()
    
    init() {
        checkPermissions()
        requestAccessibilityPermissions()
    }
    
    func checkPermissions() {
        isAccessibilityPermissionGranted()
    }
    
    private func isAccessibilityPermissionGranted() {
        let hasPermission = AXIsProcessTrusted()
        alert = hasPermission ? .none : .noAccessibilityPermission
    }
    
    private func requestAccessibilityPermissions() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        
        AXIsProcessTrustedWithOptions(options)
    }
}
