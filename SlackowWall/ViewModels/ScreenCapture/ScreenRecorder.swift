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
    @ObservedObject private var shortcutManager = ShortcutManager.shared
    @ObservedObject private var obsManager = OBSManager.shared
    
    @Published var selectedDisplay: SCDisplay? {
        didSet {
            updateEngine()
        }
    }

    @Published var selectedWindow: SCWindow? {
        didSet {
            updateEngine()
        }
    }
    
    @Published var isAppExcluded = true {
        didSet {
            updateEngine()
        }
    }
    
    @Published var isRunning = false
    @Published var contentSizes: [CGSize] = []

    /// A view that renders the screen content.
    @Published var capturePreviews: [CapturePreview] = []

    @Published private(set) var availableDisplays = [SCDisplay]()
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

    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have Screen Recording permission, this call generates an exception.
                print("Checking for permission to screen")
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                print("verdict achieved! true")
                return true
            } catch {
                print("verdict achieved! false", error.localizedDescription)
                return false
            }
        }
    }
    
    private var contentFilters: [SCContentFilter] {
        var filters: [SCContentFilter] = []
        let instances = shortcutManager.instanceNums
        
        availableWindows.sort { window, window2 in
            (instances[window.owningApplication?.processID ?? 0] ?? 0) < (instances[window2.owningApplication?.processID ?? 0] ?? 0)
        }
        
        if !obsManager.acted {
            obsManager.storeWindowIDs(info: availableWindows.map { 
                (instances[$0.owningApplication?.processID ?? 0] ?? 0, $0.windowID) })
        }
        
        for window in availableWindows {
            if windowFilters[window.windowID] == nil {
                let filter = SCContentFilter(desktopIndependentWindow: window)
                windowFilters[window.windowID] = filter
                contentSizes.append(CGSize(width: filter.contentRect.width, height: filter.contentRect.height))
                filters.append(filter)
                print("Appended filter: \(window.displayName) \(window.owningApplication?.processID ?? 0)")
            }
        }
        
        return filters
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
        
        // Set the capture interval at 15 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 15)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 6
        
        return streamConfig
    }
    
    /// Starts capturing screen content.
    func start() async {
        // Exit early if already running.
        guard !isRunning else {
            return
        }

        if !isSetup {
            // Starting polling for available screen content.
            await refreshAvailableContent()
            isSetup = true
        }

        // Update the running state.
        isRunning = true
        let filters = contentFilters
        for idx in filters.indices {
            let capturePreview = CapturePreview()
            capturePreviews.append(capturePreview)
            
            let streamConfiguration = createStreamConfiguration(width: contentSizes[idx].width, height: contentSizes[idx].height)

            Task {
                do {
                    for try await frame in captureEngine.startCapture(configuration: streamConfiguration, filter: filters[idx]) {
                        capturePreview.updateFrame(frame)
                    }
                } catch let error {
                    logger.error("\(error.localizedDescription)")
                    // Unable to start the stream. Set the running state to false.
                    InstanceManager.shared.showInfo = true
                    isRunning = false
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
    
    func resetAndStartCapture() async {
        // Stop the current capture if it's running
        if isRunning {
            await stop(removeStreams: true)
        }
        
        shortcutManager.fetchInstanceInfo()
        shortcutManager.instanceIDs.forEach(shortcutManager.resizeReset)
            
        // 40ms delay so macOS can catch up, a hack yes, but lol?
        try? await Task.sleep(nanoseconds: 40_000_000)
        
        // Reset the properties to their initial state
        capturePreviews.removeAll()
        contentSizes.removeAll()
        
        isSetup = false
        
        availableWindows.removeAll()
        availableDisplays.removeAll()
        windowFilters.removeAll()
        obsManager.acted = false
        
        // Start the capture process again
        await start()
        
        if InstanceManager.shared.shouldHideWindows {
            shortcutManager.unhideInstances()
        }
    }

    // - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else {
            return
        }
        Task {
            for idx in contentFilters.indices {
                let streamConfiguration = createStreamConfiguration(width: contentSizes[idx].width, height: contentSizes[idx].height)
                await captureEngine.update(configuration: streamConfiguration, filter: contentFilters[idx])
            }
        }
    }

    // - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            //ShortcutManager.shared.fetchInstanceInfo()
            
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            availableDisplays = availableContent.displays

            let windows = filterWindows(availableContent.windows)
            if windows != availableWindows {
                availableWindows = windows
            }
            availableApps = availableContent.applications

            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
            if selectedWindow == nil {
                selectedWindow = availableWindows.first
            }
        } catch {
            logger.error("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }

    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        // Remove all windows that are not Minecraft Instances
        windows
            .filter({ $0.displayName.contains("Minecraft") && shortcutManager.instanceIDs.contains($0.owningApplication?.processID ?? 0) })
    }
}

