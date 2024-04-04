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
    
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    
    @State private var isStopping = false
    
    var body: some Scene {
        Window("SlackowWall", id: "slackowwall-window") {
            ContentView()
            .frame(minWidth: 300, minHeight: 200)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack {
                        Button(action: {
                            isStopping = true
                            Task {
                                ShortcutManager.shared.killAll()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    exit(0)
                                }
                            }
                        }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .opacity(shortcutManager.instanceIDs.isEmpty ? 0 : 1)
                        .disabled(isStopping)
                        
                        Button(action: { Task { openWindow(id: "settings-window") }}) {
                            Image(systemName: "gear")
                        }
                        Button(action: { Task { await ScreenRecorder.shared.resetAndStartCapture() }}) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .animation(.linear, value: shortcutManager.instanceIDs)
                }
            }
        }
        .windowResizability(.contentSize)
        
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
        OBSManager.shared.writeScript()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
