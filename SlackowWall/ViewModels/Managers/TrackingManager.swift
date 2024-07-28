//
//  TrackingManager.swift
//  SlackowWall
//
//  Created by Kihron on 7/20/24.
//

import SwiftUI

class TrackingManager: ObservableObject {
    @Published var trackedInstances = [TrackedInstance]()
    
    var isCaptureReady: Bool {
        return trackedInstances.contains(where: { $0.stream.captureFilter != nil })
    }
    
    static let shared = TrackingManager()
    
    init() {
        fetchInstances()
    }
    
    func getValues<T>(_ path: KeyPath<TrackedInstance, T>) -> [T] {
        return trackedInstances.lazy.map { $0[keyPath: path] }
    }
    
    func fetchInstances() {
        // Get the list of currently running Minecraft applications
        let currentApps = getAllApps().filter { isMinecraftInstance(app: $0) }
        let currentPIDs = Set(currentApps.map { $0.processIdentifier })
        
        // Update existing instances and remove those no longer running
        trackedInstances.removeAll { trackedInstance in
            if currentPIDs.contains(trackedInstance.pid) {
                // Update existing tracked instance
                trackedInstance.stream.clearCapture()
                return false
            } else {
                // Remove instance that no longer exists
                LogManager.shared.appendLog("Removing instance \(trackedInstance.instanceNumber)")
                return true
            }
        }
        
        // Add new instances
        currentApps.forEach { app in
            if !trackedInstances.contains(where: { $0.pid == app.processIdentifier }) {
                if let trackedInstance = createTrackedInstance(app: app) {
                    trackedInstances.append(trackedInstance)
                }
            }
        }
        
        // Sort the trackedInstances array by instanceNumber
        trackedInstances.sort { $0.instanceNumber < $1.instanceNumber }
        
        // Log the tracked instances
        LogManager.shared.appendLog("Tracked Instances:", trackedInstances.map { $0.pid })
        logStatePaths()
    }
    
    private func createTrackedInstance(app: NSRunningApplication) -> TrackedInstance? {
        guard isMinecraftInstance(app: app),
              let args = Utilities.processArguments(pid: app.processIdentifier),
              let nativesArg = args.first(where: { $0.starts(with: "-Djava.library.path=") }) else {
            return nil
        }
        
        let numString = nativesArg
            .dropFirst("-Djava.library.path=".count)
            .dropLast("/natives".count)
        
        if let num = UInt(numString.suffix(2)) ?? UInt(numString.suffix(1)) {
            return TrackedInstance(pid: app.processIdentifier, instanceNumber: Int(num))
        }
        
        return nil
    }
    
    private func isMinecraftInstance(app: NSRunningApplication) -> Bool {
        guard let args = Utilities.processArguments(pid: app.processIdentifier) else {
            return false
        }
        
        let minecraftArgs = ["net.minecraft.client.main.Main", "-Djava.library.path="]
        return minecraftArgs.contains { arg in args.contains(where: { $0.contains(arg) }) }
    }
    
    private func getAllApps() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
    }
    
    private func logStatePaths() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        trackedInstances.map({$0.info }).forEach { info in
            let sanitizedPath = info.statePath.replacingOccurrences(of: homeDirectory, with: "~")
            LogManager.shared.appendLog(sanitizedPath, showInConsole: false)
        }
    }
    
    func killAll() {
        let runningApps = getAllApps()
        var appsToTerminate: [NSRunningApplication] = []
        
        // Send terminate signal to the apps
        for app in runningApps {
            if trackedInstances.first(where: { $0.pid == app.processIdentifier }) != nil {
                app.terminate()
                appsToTerminate.append(app)
                LogManager.shared.appendLog("Terminating Instance:", app.processIdentifier, showInConsole: false)
            }
        }
        
        // Check if the apps have terminated
        let queue = DispatchQueue.global(qos: .background)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: 0.1)
        
        timer.setEventHandler {
            if appsToTerminate.allSatisfy({ $0.isTerminated }) {
                timer.cancel()
                DispatchQueue.main.async {
                    LogManager.shared.appendLog("Closed SlackowWall", showInConsole: false)
                    exit(0)
                }
            }
        }
        
        timer.resume()
    }
}
