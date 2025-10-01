//
//  AlertManager.swift
//  SlackowWall
//
//  Created by Kihron on 5/21/24.
//

import Combine
@preconcurrency import ScreenCaptureKit
import SwiftUI

@MainActor
class AlertManager: ObservableObject {
    @Published var alert: WallAlert? = .none

    @Published var showErrorAlert = false
    @Published var errorAlert: String?

    static let shared = AlertManager()

    init() {
        checkPermissions()
        requestAccessibilityPermissions()

        // Setup notification observer for utility mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(utilityModeChanged),
            name: NSNotification.Name("UtilityModeChanged"),
            object: nil
        )
    }

    @objc private func utilityModeChanged() {
        // If we're in utility mode, clear screen recording alerts
        if !ScreenRecorder.shared.needsRecordingPerms && alert == .noScreenPermission {
            alert = nil
        } else if ScreenRecorder.shared.needsRecordingPerms {
            // If we're leaving utility mode, check for screen recording permission
            Task {
                await checkScreenRecordingPermission()
            }
        }
    }

    func dismissableError(message: String) {
        self.errorAlert = message
        self.showErrorAlert = true
    }

    func checkPermissions() {
        // Check for accessibility permissions
        isAccessibilityPermissionGranted()

        // Check for screen recording permissions only if not in utility mode
        // This is now handled by the utilityModeChanged observer which will be triggered
        // immediately after initialization
        utilityModeChanged()
    }

    private func isAccessibilityPermissionGranted() {
        let hasPermission = AXIsProcessTrusted()
        if !hasPermission {
            alert = .noAccessibilityPermission
        }
    }

    func checkScreenRecordingPermission() async -> Bool {
        if Settings[\.behavior].utilityMode {
            return true  // Skip check in utility mode
        }

        do {
            LogManager.shared.appendLog("Checking for screen capture permissions")
            try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            LogManager.shared.appendLog("Screen recording permission granted")

            // Clear any existing screen permission alert
            if alert == .noScreenPermission {
                DispatchQueue.main.async {
                    self.alert = nil
                }
            }
            return true
        } catch {
            LogManager.shared.appendLog(
                "Screen recording permission denied: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.alert = .noScreenPermission
            }
            return false
        }
    }

    private func requestAccessibilityPermissions() {
        let options =
            [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
            ] as CFDictionary

        AXIsProcessTrustedWithOptions(options)
    }

    func requestScreenRecordingPermission() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        {
            NSWorkspace.shared.open(url)
        }
    }

    func requestAccessibilityPermission() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        {
            NSWorkspace.shared.open(url)
        }
    }
}
