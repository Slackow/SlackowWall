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
    
    var body: some Scene {
        Window("SlackowWall", id: "slackowwall-window") {
            ContentView()
            .frame(minWidth: 300, minHeight: 200)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            if !trackingManager.trackedInstances.isEmpty {
                                ToolbarStopView()
                            }
                            
                            if alertManager.alert != nil {
                                ToolbarAlertView()
                            }
                        }
                        .frame(width: 48, height: 40, alignment: .trailing)
                        .animation(.easeInOut(duration: 0.3), value: trackingManager.trackedInstances)
                        .animation(.easeInOut(duration: 0.3), value: alertManager.alert)
                        
                        ToolbarSettingsView()
                        
                        ToolbarRefreshView()
                    }
                }
            }
        }
        .windowResizability(.contentSize)
        
        Window("Settings", id: "settings-window") {
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
                            ): "Copyright © 2024 Slackow, Kihron."
                        ]
                    )
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button(action: { openWindow(id: "settings-window") }) {
                    Text("Settings...")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .appInfo, addition: {
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
                }
            }
        }
        .windowResizability(.contentSize)
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var eventMonitor: Any?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Monitor for global key presses
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyUp]) { event in
            ShortcutManager.shared.handleGlobalKey(event)
        }
        OBSManager.shared.writeScript()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
