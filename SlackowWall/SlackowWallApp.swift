//
//  SlackowWallApp.swift
//  SlackowWall
//
//  Created by Andrew on 8/1/22.
//

import SwiftUI

@main
struct SlackowWallApp: App {
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @ObservedObject private var trackingManager = TrackingManager.shared
    @ObservedObject private var instanceManager = InstanceManager.shared
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var alertManager = AlertManager.shared
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @AppSettings(\.profile)
    private var profile
    @AppSettings(\.behavior)
    private var behavior
    @AppSettings(\.utility)
    private var utility

    @State private var showLogUploadedAlert = false
    @State private var logUploadedAlert: String?
    @State private var logLink: String?

    init() {
        NSSplitViewItem.swizzle()
    }

    var body: some Scene {
        Window("SlackowWall", id: SWWindowID.slackowwall.rawValue) {
            ContentView()
                .frame(minWidth: 300, minHeight: 210)
                .toolbar {
                    if !trackingManager.trackedInstances.isEmpty && !behavior.utilityMode {
                        ToolbarItem {
                            ToolbarStopView()
                        }
                    }
                    if alertManager.alert != nil {
                        ToolbarItem {
                            ToolbarAlertView()
                                .animation(
                                    .easeInOut(duration: 0.3),
                                    value: trackingManager.trackedInstances
                                )
                                .animation(.easeInOut(duration: 0.3), value: alertManager.alert)
                        }
                    }
                    if utility.sensitivityScaleToolBarIcon {
                        ToolbarItem {
                            ToolbarSensitivityToggleView()
                        }
                    }
                    if utility.pacemanToolBarIcon {
                        ToolbarItem {
                            ToolbarPacemanToggleView()
                        }
                    }
                    ToolbarItemGroup {
                        ToolbarUtilityModeView()
                        ToolbarSettingsView()
                        ToolbarRefreshView()
                    }

                }
                .navigationTitle("SlackowWall - Profile: \(profile.name)")
                .alert(
                    "Log File Upload", isPresented: $showLogUploadedAlert,
                    presenting: logUploadedAlert
                ) { _ in
                    if let logLink {
                        Button("Copy Link") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(logLink, forType: .string)
                        }
                    }
                    Button("Close") {}
                } message: { _ in
                    Text(logUploadedAlert ?? "Unable to upload.")
                }
                .alert(
                    "Error: \(alertManager.errorAlert ?? "")",
                    isPresented: $alertManager.showErrorAlert,
                    actions: { Button("OK", role: .cancel) {} })
        }
        .windowResizability(.contentSize)

        Window("Settings", id: SWWindowID.settings.rawValue) {
            SettingsView()
                .frame(minWidth: 700, maxWidth: 700, minHeight: 455, alignment: .center)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About SlackowWall") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "Multi-Instance Manager for macOS",
                                attributes: [
                                    NSAttributedString.Key.font: NSFont.boldSystemFont(
                                        ofSize: NSFont.smallSystemFontSize)
                                ]
                            ),
                            NSApplication.AboutPanelOptionKey(
                                rawValue: "Copyright"
                            ): "Copyright © 2025 Slackow, Kihron.",
                        ]
                    )
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button(action: { openWindow(id: SWWindowID.settings.rawValue) }) {
                    Text("Settings...")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(
                after: .appInfo,
                addition: {
                    Button("Check for updates...") {
                        UpdateManager.shared.checkForUpdates()
                    }
                })
            CommandGroup(after: .help) {
                Divider()

                Menu("Log Files") {
                    Button(action: LogManager.shared.openLogFolder) {
                        Text("Show Log Files")
                    }

                    Button(action: LogManager.shared.openLatestLogInConsole) {
                        Text("View Current Log")
                    }

                    Button(action: {
                        LogManager.shared.uploadLog { msg, link in
                            logUploadedAlert = msg
                            logLink = link
                            showLogUploadedAlert = true
                        }
                    }) {
                        Text("Upload Current Log")
                    }
                }
            }
        }
        .windowResizability(.contentSize)

        Window("Eye Projector", id: SWWindowID.eyeProjector.rawValue) {
            EyeProjectorWindowView()
                .frame(minWidth: 300, minHeight: 200)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.trailing)
        .defaultSize(width: 600, height: 400)
        .onChange(of: shortcutManager.eyeProjectorOpen) { newValue in
            if newValue {
                openWindow(id: SWWindowID.eyeProjector.rawValue)
                NSApp.setWindowFloating(.eyeProjector, isFloating: utility.eyeProjectorAlwaysOnTop)
                NSApp.setTitleBarVisibility(
                    .eyeProjector, isHidden: Settings[\.utility].eyeProjectorTitleBarHidden)
            }
        }

        Window("Pie Projector", id: SWWindowID.pieProjector.rawValue) {
            PieProjectorWindowView()
                .frame(minWidth: 384, minHeight: 384)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.bottom)
        .defaultSize(width: 384, height: 384)
        .onChange(of: shortcutManager.pieProjectorOpen) { newValue in
            if newValue {
                openWindow(id: SWWindowID.pieProjector.rawValue)
                NSApp.setWindowFloating(.pieProjector, isFloating: utility.pieProjectorAlwaysOnTop)
                NSApp.setTitleBarVisibility(
                    .pieProjector, isHidden: Settings[\.utility].pieProjectorTitleBarHidden)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var eventMonitor: Any?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Monitor for global key presses
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .keyDown, .keyUp, .flagsChanged,
        ]) { event in
            ShortcutManager.shared.handleGlobalKey(event)
        }
        OBSManager.shared.writeScript()
        MouseSensitivityManager.shared.setSensitivityFactor(
            factor: Settings[\.utility].sensitivityScale)
        #if !DEBUG
            if Settings[\.utility].autoLaunchPaceman {
                PacemanManager.shared.startPaceman()
            }
            if Settings[\.utility].startupApplicationEnabled {
                Settings[\.utility].startupApplications.forEach {
                    let path = $0.path(percentEncoded: false)
                    let task = Process()
                    if path.hasSuffix(".jar") {
                        task.executableURL = URL(filePath: "/usr/bin/env")
                        task.arguments = ["java", "-jar", path]
                    } else {
                        task.executableURL = URL(filePath: "/usr/bin/open")
                        task.arguments = [path]
                    }
                    try? task.run()
                }
            }
        #endif
        WindowController.startup()
        // Start the instance check timer
        TrackingManager.shared.startInstanceCheckTimer()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up the timer when the app is about to terminate
        TrackingManager.shared.stopInstanceCheckTimer()
    }
}
