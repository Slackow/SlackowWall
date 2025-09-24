//
//  ScreenRecorder.swift
//  SlackowWall
//
//  Created by Kihron on 1/12/23.
//

import Combine
import OSLog
@preconcurrency import ScreenCaptureKit
import SwiftUI

@MainActor class ScreenRecorder: ObservableObject {
    @ObservedObject private var trackingManager = TrackingManager.shared
    @ObservedObject private var obsManager = OBSManager.shared

    @Published var isRunning = false
    @Published private(set) var availableWindows = [SCWindow]()
    @Published var eyeProjectedInstance: TrackedInstance? = nil
    @Published var eyeProjectorMode: EyeProjectorMode = .tall

    // Dedicated eye projector capture that works regardless of utility mode
    private var eyeProjectorCapture: CaptureEngine? = nil
    private var eyeProjectorFilter: SCContentFilter? = nil

    private var availableApps = [SCRunningApplication]()
    private var windowFilters: [CGWindowID: SCContentFilter] = [:]

    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()

    private var isSetup = false

    private let logger = Logger()

    static let shared = ScreenRecorder()

    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()

    @AppSettings(\.behavior) private var behavior
    @AppSettings(\.profile) private var profile
    @AppSettings(\.personalize) private var personalize

    var needsRecordingPerms: Bool {
        !behavior.utilityMode || Settings[\.utility].eyeProjectorEnabled
    }

    var needsEyeProjectorCapture: Bool {
        Settings[\.utility].eyeProjectorEnabled
    }

    func startCapture() async {
        LogManager.shared.appendLog("Attempting to start screen capture...")
        guard needsRecordingPerms else {
            // Skip screen recording permission check in utility mode
            LogManager.shared.appendLog("Utility mode active - skipping screen capture")
            return
        }

        if await canRecord {
            await resetAndStartCapture()
        }
    }

    func startEyeProjectorCapture(
        for instance: TrackedInstance,
        mode: EyeProjectorMode = .tall
    ) async {
        guard needsEyeProjectorCapture else { return }

        // Always check permissions for eye projector capture
        guard await AlertManager.shared.checkScreenRecordingPermission() else { return }

        eyeProjectorMode = mode
        await setupEyeProjectorCapture(for: instance)
    }

    var canRecord: Bool {
        get async {
            // Don't need to check permissions in utility mode
            if !needsRecordingPerms {
                return false
            }

            // Use the AlertManager to check permissions and show alert if needed
            return await AlertManager.shared.checkScreenRecordingPermission()
        }
    }

    private func refreshContentFilters() {
        availableWindows.sort { window, window2 in
            guard let pid1 = window.owningApplication?.processID,
                let pid2 = window2.owningApplication?.processID,
                let instance1 = trackingManager.trackedInstances.first(where: { $0.pid == pid1 }),
                let instance2 = trackingManager.trackedInstances.first(where: { $0.pid == pid2 })
            else {
                return false
            }
            return instance1.instanceNumber < instance2.instanceNumber
        }

        for window in availableWindows where windowFilters[window.windowID] == nil {
            if let pid = window.owningApplication?.processID,
                let trackedInstance = trackingManager.trackedInstances.first(where: {
                    $0.pid == pid
                })
            {
                trackedInstance.windowID = window.windowID

                let filter = SCContentFilter(desktopIndependentWindow: window)
                windowFilters[window.windowID] = filter
                trackedInstance.stream.captureFilter = filter
                LogManager.shared.appendLog(
                    "Created Filter: (\(window.displayName)) (\(window.owningApplication?.processID ?? 0))"
                )
            }
        }
    }

    private func createStreamConfiguration(width: CGFloat, height: CGFloat) -> SCStreamConfiguration
    {
        let streamConfig = SCStreamConfiguration()

        // Configure audio capture.
        streamConfig.capturesAudio = false
        streamConfig.showsCursor = false
        streamConfig.excludesCurrentProcessAudio = false
        streamConfig.scalesToFit = true

        // Configure the window content width and height.
        streamConfig.width = Int(width)
        streamConfig.height = Int(height)

        // Set the capture interval.
        streamConfig.minimumFrameInterval = CMTime(
            value: 1, timescale: CMTimeScale(personalize.streamFPS))

        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 6

        return streamConfig
    }

    /// Starts capturing screen content.
    private func start() async {
        // Exit early if already running.
        guard !isRunning else {
            return
        }

        if !isSetup {
            // Start polling for available screen content.
            await refreshAvailableContent()
            isSetup = true
        }

        // Update the running state.
        isRunning = true
        LogManager.shared.appendLog("Screen capture started")
        refreshContentFilters()

        if #available(macOS 14.0, *) {
            for instance in trackingManager.trackedInstances {
                guard let filter = instance.stream.captureFilter else { continue }
                let streamConfiguration = createStreamConfiguration(
                    width: filter.contentRect.width, height: filter.contentRect.height)

                instance.stream.captureRect = CGSize(
                    width: filter.contentRect.width, height: filter.contentRect.height)

                Task {
                    do {
                        for try await frame in captureEngine.startCapture(
                            configuration: streamConfiguration, filter: filter)
                        {
                            await MainActor.run {
                                instance.stream.capturePreview.updateFrame(frame)
                            }
                        }
                    } catch let error {
                        logger.error("\(error.localizedDescription)")
                        LogManager.shared.appendLog(
                            "Stream error (\(instance.pid)):", error.localizedDescription,
                            error.self)

                        if let error = error as? SCStreamError {
                            let streamError = StreamError(errorCode: error.errorCode)
                            switch streamError {
                                case .appClosed:
                                    instance.wasClosed = true
                                case .unknown:
                                    instance.stream.streamError = streamError
                                    GridManager.shared.showInfo = true
                            }
                        }
                    }
                }
            }
        }
    }

    // Stops capturing screen content.
    func stop(removeStreams: Bool = false) async {
        guard isRunning else {
            return
        }
        await captureEngine.stopCapture(removeStreams: removeStreams)
        isRunning = false
    }

    func stopEyeProjectorCapture() async {
        if let eyeProjectorCapture = eyeProjectorCapture {
            await eyeProjectorCapture.stopCapture(removeStreams: true)
            self.eyeProjectorCapture = nil
            self.eyeProjectorFilter = nil
        }
    }

    func resumeCapture() async {
        guard !isRunning else {
            return
        }

        await captureEngine.resumeCapture()
        isRunning = true
    }

    func resetAndStartCapture(shouldAutoSwitch: Bool = true) async {
        // Stop the current capture if it's running
        if isRunning {
            LogManager.shared.appendLog("Refreshing screen capture...")
            await stop(removeStreams: true)
        }

        // Reset the properties to their initial state
        isSetup = false
        availableWindows.removeAll()
        windowFilters.removeAll()

        if shouldAutoSwitch {
            if let screen = NSScreen.primary?.frame,
                profile.expectedMWidth != Int(screen.width)
                    || profile.expectedMHeight != Int(screen.height)
            {
                Settings.shared.autoSwitch()
            }
        }

        trackingManager.fetchInstances()
        MouseSensitivityManager.shared.setSensitivityFactor(
            factor: Settings[\.utility].sensitivityScale)

        if !behavior.utilityMode {
            // Only check screen recording permission and start capture when not in utility mode
            LogManager.shared.appendLog("Normal mode - preparing screen capture")

            // 40ms delay so macOS can catch up, a hack yes, but lol?
            try? await Task.sleep(nanoseconds: 40_000_000)

            // Start the capture process again
            await start()
        } else {
            LogManager.shared.appendLog("Utility mode - skipping screen capture")
        }
    }

    // - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: false)

            let windows = filterWindows(availableContent.windows)
            if windows != availableWindows {
                availableWindows = windows
            }
            availableApps = availableContent.applications
        } catch {
            logger.error("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }

    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows.filter { window in
            guard let processID = window.owningApplication?.processID, let title = window.title
            else { return false }

            let regex = /1\.(\d+)(\.\d+)?/
            if let match = try? regex.firstMatch(in: title),
                let majorVersion = Int(match.output.1),
                majorVersion >= 6,
                title.contains("Minecraft")
            {
                return trackingManager.getValues(\.pid).contains(processID)
            }

            return (title.contains("Prism Launcher") || title.contains("MultiMC"))
                && trackingManager.trackedInstances.contains(where: { $0.pid == processID })
        }
    }

    private func setupEyeProjectorCapture(for instance: TrackedInstance) async {
        // Stop any existing eye projector capture
        await stopEyeProjectorCapture()

        // Attempt to reuse the stored filter for this instance to avoid the
        // expensive window enumeration that occurs when starting the eye
        // projector.
        var filter: SCContentFilter?

        if let windowID = instance.windowID,
            let storedFilter = windowFilters[windowID]
        {
            filter = storedFilter
        } else {
            // Refresh available windows only if needed
            await refreshAvailableContent()

            guard
                let window = availableWindows.first(where: {
                    $0.owningApplication?.processID == instance.pid
                })
            else {
                LogManager.shared.appendLog(
                    "Could not find window for eye projector instance \(instance.pid)"
                )
                return
            }

            let newFilter = SCContentFilter(desktopIndependentWindow: window)
            windowFilters[window.windowID] = newFilter
            instance.windowID = window.windowID
            filter = newFilter
        }

        guard let filter else {
            LogManager.shared.appendLog(
                "Unable to setup filter for eye projector instance \(instance.pid)"
            )
            return
        }

        // Use tall mode dimensions instead of actual window size
        var (tallWidth, tallHeight, _, _) = Settings.shared.preferences.tallDimensions(for: instance)
        let usingRetino = instance.info.mods.map(\.id).contains("retino")
//        let factor = usingRetino ? 1 : (NSScreen.primary?.backingScaleFactor ?? 1)
        let factor = 16384.0 / tallHeight
        tallWidth *= factor
        tallHeight *= factor
        
        LogManager.shared.appendLog("Starting Eye Projector: dim:(", tallWidth, "x", tallHeight, ") factor:", factor, "usingRetino:", usingRetino)

        let streamConfig = createStreamConfiguration(
            width: tallWidth,
            height: tallHeight
        )
        streamConfig.minimumFrameInterval = CMTime(
            value: 1, timescale: CMTimeScale(30))
        

        // Store the filter and create dedicated capture engine
        eyeProjectorFilter = filter
        eyeProjectorCapture = CaptureEngine()

        // Update the instance's eye projector stream capture filter and rect with tall mode dimensions
        instance.eyeProjectorStream.captureFilter = filter
        instance.eyeProjectorStream.captureRect = CGSize(
            width: tallWidth,
            height: tallHeight
        )

        // Start the dedicated capture
        guard let eyeProjectorCapture = eyeProjectorCapture else { return }

        Task {
            do {
                for try await frame in eyeProjectorCapture.startCapture(
                    configuration: streamConfig, filter: filter
                ) {
                    await MainActor.run {
                        instance.eyeProjectorStream.capturePreview.updateFrame(frame)
                    }
                }
            } catch let error {
                logger.error("Eye projector capture error: \(error.localizedDescription)")
                LogManager.shared.appendLog(
                    "Eye projector stream error (\(instance.pid)):",
                    error.localizedDescription
                )

                if let error = error as? SCStreamError {
                    let streamError = StreamError(errorCode: error.errorCode)
                    instance.eyeProjectorStream.streamError = streamError
                }
            }
        }

        LogManager.shared.appendLog("Started eye projector capture for instance \(instance.pid)")
    }
}

