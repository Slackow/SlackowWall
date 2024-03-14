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
    
    var body: some Scene {
        Window("SlackowWall", id: "slackowwall-window") {
            ContentView()
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: { Task { await ScreenRecorder.shared.resetAndStartCapture() }}) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
        }
        
        Window("Settings", id: "settings-window") {
            SettingsView()
                .frame(minWidth: 700, maxWidth: 700, minHeight: 435, alignment: .center)
        }
        .commands {
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
            KeybindingManager.shared.handleGlobalKey(event)
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
