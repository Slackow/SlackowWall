//
//  ScreenRecorder.swift
//  SlackowWall
//
//  Created by Kihron on 1/12/23.
//

import ScreenCaptureKit
import Combine
import OSLog
import SwiftUI

@MainActor class ScreenRecorder: ObservableObject {
    @ObservedObject private var trackingManager = TrackingManager.shared
    @ObservedObject private var obsManager = OBSManager.shared
    
    @Published var isRunning = false
    @Published private(set) var availableWindows = [SCWindow]()
    
    private var availableApps = [SCRunningApplication]()
    private var windowFilters: [CGWindowID: SCContentFilter] = [:]
    
    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()
    
    private var isSetup = false
    
    private let logger = Logger()
    
    static let shared = ScreenRecorder()
    
    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()
    
    func startCapture() async {
        LogManager.shared.appendLog("Attempting to start screen capture...")
        if await canRecord {
            await resetAndStartCapture()
        }
    }
    
    var canRecord: Bool {
        get async {
            if ProfileManager.shared.profile.utilityMode {
                return false
            }
            do {
                // If the app doesn't have Screen Recording permission, this call generates an exception.
                LogManager.shared.appendLog("Checking for screen capture permissions")
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                LogManager.shared.appendLog("Verdict Achieved: true")
                return true
            } catch {
                LogManager.shared.appendLog("Verdict Achieved: false, Error: \(error.localizedDescription).")
                AlertManager.shared.alert = .noScreenPermission
                return false
            }
        }
    }
    
    private func refreshContentFilters() {
        availableWindows.sort { window, window2 in
            guard let pid1 = window.owningApplication?.processID,
                  let pid2 = window2.owningApplication?.processID,
                  let instance1 = trackingManager.trackedInstances.first(where: { $0.pid == pid1 }),
                  let instance2 = trackingManager.trackedInstances.first(where: { $0.pid == pid2 }) else {
                return false
            }
            return instance1.instanceNumber < instance2.instanceNumber
        }
        
        for window in availableWindows where windowFilters[window.windowID] == nil {
            if let pid = window.owningApplication?.processID, let trackedInstance = trackingManager.trackedInstances.first(where: { $0.pid == pid }) {
                trackedInstance.windowID = window.windowID
                
                let filter = SCContentFilter(desktopIndependentWindow: window)
                windowFilters[window.windowID] = filter
                trackedInstance.stream.captureFilter = filter
                LogManager.shared.appendLog("Created Filter: (\(window.displayName)) (\(window.owningApplication?.processID ?? 0))")
            }
        }
    }
    
    private func createStreamConfiguration(width: CGFloat, height: CGFloat) -> SCStreamConfiguration {
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
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(ProfileManager.shared.profile.streamFPS))
        
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
                let streamConfiguration = createStreamConfiguration(width: filter.contentRect.width, height: filter.contentRect.height)
                
                instance.stream.captureRect = CGSize(width: filter.contentRect.width, height: filter.contentRect.height)
                
                Task {
                    do {
                        for try await frame in captureEngine.startCapture(configuration: streamConfiguration, filter: filter) {
                            instance.stream.capturePreview.updateFrame(frame)
                        }
                    } catch let error {
                        logger.error("\(error.localizedDescription)")
                        LogManager.shared.appendLog("Stream error (\(instance.pid)):", error.localizedDescription, error.self)
                        
                        if let error = error as? SCStreamError {
                            let streamError = StreamError(errorCode: error.errorCode)
                            switch streamError {
                                case .appClosed:
                                    instance.wasClosed = true
                                    //                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    //                                    Task {
                                    //                                        GridManager.shared.showInfo = false
                                    //                                        self.trackingManager.trackedInstances.removeAll(where: { $0 == instance })
                                    //                                        await self.resetAndStartCapture()
                                    //                                    }
                                    //                                }
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
            if let screen = NSScreen.main?.frame,
               ProfileManager.shared.profile.expectedMWidth != Int(screen.width) ||
                ProfileManager.shared.profile.expectedMHeight != Int(screen.height) {
                ProfileManager.shared.autoSwitch()
            }
        }
        
        trackingManager.fetchInstances()
        trackingManager.getValues(\.pid).forEach(ShortcutManager.shared.resizeReset)

        if ProfileManager.shared.profile.shouldHideWindows && !ProfileManager.shared.profileCreatedOrDeleted {
            WindowController.unhideWindows(trackingManager.getValues(\.pid))
        }
        if !ProfileManager.shared.profile.utilityMode {
            // 40ms delay so macOS can catch up, a hack yes, but lol?
            try? await Task.sleep(nanoseconds: 40_000_000)
            
            // Start the capture process again
            await start()
        }
    }
    
    // - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            
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
            guard let processID = window.owningApplication?.processID, let title = window.title else { return false }
            
            let versionPattern = "1\\.(\\d+)(\\.\\d+)?"
            let regex = try? NSRegularExpression(pattern: versionPattern)
            let matches = regex?.matches(in: title, range: NSRange(title.startIndex..., in: title))
            
            if let match = matches?.first,
               let majorRange = Range(match.range(at: 1), in: title),
               let majorVersion = Int(title[majorRange]),
               majorVersion >= 6,
               title.contains("Minecraft") {
                return trackingManager.trackedInstances.contains(where: { $0.pid == processID })
            }
            
            return (title.contains("Prism Launcher") || title.contains("MultiMC")) && trackingManager.trackedInstances.contains(where: { $0.pid == processID })
        }
    }
}
