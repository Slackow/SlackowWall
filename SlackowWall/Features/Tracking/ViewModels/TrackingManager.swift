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

    // Timer for automatic instance detection
    private var instanceCheckTimer: Timer?
    private var lastCheckedPIDs = Set<pid_t>()

    // Time interval for checking instances (in seconds)
    private let instanceCheckInterval: TimeInterval = 2.0

    init() {
        fetchInstances()
        startInstanceCheckTimer()
    }

    deinit {
        stopInstanceCheckTimer()
    }

    func getValues<T>(_ path: KeyPath<TrackedInstance, T>) -> [T] {
        return trackedInstances.lazy.map { $0[keyPath: path] }
    }

    func fetchInstances() {
        // Get the list of currently running Minecraft applications
        let currentApps = getAllApps().filter(isMinecraftInstance)
        let currentPIDs = Set(currentApps.map(\.processIdentifier))

        // Update existing instances and remove those no longer running
        trackedInstances.removeAll { trackedInstance in
            if currentPIDs.contains(trackedInstance.pid) {
                // Update existing tracked instance
                trackedInstance.stream.clearCapture()
                return false
            } else {
                // Remove instance that no longer exists
                LogManager.shared.appendLog("Removing instance \(trackedInstance.pid)")
                return true
            }
        }

        // Add new instances
        LogManager.shared
            .appendLog("Adding Instances:")
            .appendLogNewLine()
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
        LogManager.shared.appendLog("Tracked Instances:", trackedInstances.map(\.pid))
        logStatePaths()
    }

    private func createTrackedInstance(app: NSRunningApplication) -> TrackedInstance? {
        guard isMinecraftInstance(app: app),
            let args = Utilities.processArguments(pid: app.processIdentifier),
            let nativesArg = args.first(where: { $0.starts(with: "-Djava.library.path=") })
        else {
            return nil
        }

        let numString =
            nativesArg
            .dropFirst("-Djava.library.path=".count)
            .dropLast("/natives".count)

        if !Settings[\.behavior].utilityMode,
            let num = UInt(numString.suffix(2)) ?? UInt(numString.suffix(1))
        {
            return TrackedInstance(pid: app.processIdentifier, instanceNumber: Int(num))
        }
        let instNum = (self.getValues(\.instanceNumber).max() ?? 0) + 1
        return TrackedInstance(pid: app.processIdentifier, instanceNumber: instNum)
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
        trackedInstances.map({ $0.info }).forEach { info in
            LogManager.shared.logPath(info.statePath, showInConsole: false)
        }
    }

    // MARK: - Instance Check Timer

    /// Start the timer that periodically checks for Minecraft instances
    func startInstanceCheckTimer() {
        // Stop any existing timer first
        stopInstanceCheckTimer()

        // Initialize with current PIDs - make sure to include all tracked instances
        fetchInstances()
        lastCheckedPIDs = Set(trackedInstances.map { $0.pid })

        // Create a new timer that fires at the configured interval
        let timer = Timer.scheduledTimer(
            timeInterval: instanceCheckInterval,
            target: self,
            selector: #selector(checkForInstanceChanges),
            userInfo: nil,
            repeats: true
        )
        instanceCheckTimer = timer

        // Make sure timer runs even during scrolling
        RunLoop.current.add(timer, forMode: .common)

        LogManager.shared.appendLog(
            "Instance change detection timer started (checking every \(instanceCheckInterval) seconds)"
        )
    }

    /// Stop the instance check timer
    func stopInstanceCheckTimer() {
        instanceCheckTimer?.invalidate()
        instanceCheckTimer = nil
    }

    /// Check for changes in Minecraft instances (added or removed)
    @objc private func checkForInstanceChanges() {
        // Get the current Minecraft apps
        let currentApps = getAllApps().filter(isMinecraftInstance)
        let currentPIDs = Set(currentApps.map(\.processIdentifier))

        // If there's no change in the set of PIDs, do nothing
        guard currentPIDs != lastCheckedPIDs else {
            return
        }

        // Calculate what changed
        let addedPIDs = currentPIDs.subtracting(lastCheckedPIDs)
        let removedPIDs = lastCheckedPIDs.subtracting(currentPIDs)

        // Only process if there are actual changes
        if !addedPIDs.isEmpty || !removedPIDs.isEmpty {
            // Log the changes with detailed info
            if !addedPIDs.isEmpty {
                let newInstances = currentApps.filter { addedPIDs.contains($0.processIdentifier) }
                let instanceNames = newInstances.map { $0.localizedName ?? "Unknown" }
                LogManager.shared.appendLog(
                    "New Minecraft instances detected: \(addedPIDs) - \(instanceNames)")
            }

            if !removedPIDs.isEmpty {
                LogManager.shared.appendLog("Minecraft instances closed: \(removedPIDs)")
            }

            // Update the tracked instances
            updateInstancesAndRefresh()
        }

        // Always update the last checked PIDs
        lastCheckedPIDs = currentPIDs
    }

    /// Update tracked instances and refresh the capture
    private func updateInstancesAndRefresh() {
        // Refresh TrackedInstances and trigger a capture refresh
        Task {
            await ScreenRecorder.shared.resetAndStartCapture()
        }
    }

    @discardableResult
    func kill(instance: TrackedInstance) -> NSRunningApplication? {
        let killed = getAllApps().first(where: { $0.processIdentifier == instance.pid })
        killed?.terminate()
        return killed
    }

    @discardableResult
    func killAndWait(instance: TrackedInstance) async -> Bool {
        guard let killed = getAllApps().first(where: { $0.processIdentifier == instance.pid })
        else { return false }
        guard killed.terminate() else { return false }
        for i in 0..<25 {
            LogManager.shared.appendLog("Termination check \(i + 1)/25")
            if killed.isTerminated { return true }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return false
    }

    func killAll() {
        let runningApps = getAllApps()
        var appsToTerminate: [NSRunningApplication] = []

        // Send terminate signal to the apps
        for app in runningApps {
            if trackedInstances.first(where: { $0.pid == app.processIdentifier }) != nil {
                app.terminate()
                appsToTerminate.append(app)
                LogManager.shared.appendLog(
                    "Terminating Instance:", app.processIdentifier, showInConsole: false)
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
