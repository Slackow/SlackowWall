//
//  ScreenRecorder.swift
//  SlackowWall
//
//  Created by Kihron on 1/12/23.
//

import Foundation
import ScreenCaptureKit
import Combine
import OSLog
import SwiftUI

@MainActor
class ScreenRecorder: ObservableObject {

    private let logger = Logger()
    private var shortcutManager = ShortcutManager.shared

    @Published var isRunning = false

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

    @Published var contentSizes: [CGSize] = []
    private var scaleFactor: Int {
        Int(NSScreen.main?.backingScaleFactor ?? 2)
    }

    /// A view that renders the screen content.
    var capturePreviews: [CapturePreview] = []

    private var availableApps = [SCRunningApplication]()
    @Published private(set) var availableDisplays = [SCDisplay]()
    @Published private(set) var availableWindows = [SCWindow]()

    @Published var isAppAudioExcluded = false {
        didSet {
            updateEngine()
        }
    }
    // A value that specifies how often to retrieve calculated audio levels.

    // The object that manages the SCStream.
    private let captureEngine = CaptureEngine()

    private var isSetup = false

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
                print("verdict achieved! false")
                return false
            }
        }
    }

    func monitorAvailableContent() async {
        guard !isSetup else {
            return
        }

        // Refresh the lists of capturable content.
        await refreshAvailableContent()

        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else {
                return
            }
            Task {
                await self.refreshAvailableContent()
            }
        }
        .store(in: &subscriptions)
    }

    /// Starts capturing screen content.
    func start() async {
        // Exit early if already running.
        guard !isRunning else {
            return
        }

        if !isSetup {
            // Starting polling for available screen content.
            await monitorAvailableContent()
            isSetup = true
        }

        let config = streamConfiguration

        // Update the running state.
        isRunning = true
        let filters = contentFilters
        for idx in filters.indices {
            let capturePreview = CapturePreview()
            capturePreviews.append(capturePreview)

            let contentSize = CGSize(width: 854, height: 508)
            contentSizes.append(contentSize)

            Task {
                do {
                    for try await frame in captureEngine.startCapture(configuration: config, filter: filters[idx]) {
                        capturePreview.updateFrame(frame)
                    }
                } catch let error {
                    logger.error("\(error.localizedDescription)")
                    // Unable to start the stream. Set the running state to false.
                    isRunning = false
                }
            }
        }
    }

    /// Stops capturing screen content.
    func stop() async {
        guard isRunning else {
            return
        }
        await captureEngine.stopCapture()
        isRunning = false
    }
    
    func resumeCapture() async {
        guard !isRunning else {
            return
        }
        
        await captureEngine.resumeCapture()
        isRunning = true
    }

    /// - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else {
            return
        }
        Task {
            for idx in contentFilters.indices {
                await captureEngine.update(configuration: streamConfiguration, filter: contentFilters[idx])
            }
        }
    }

    /// - Tag: UpdateFilter
    private var contentFilters: [SCContentFilter] {
        var filters: [SCContentFilter] = []
        let instances = ShortcutManager.shared.instanceNums
        availableWindows.sort { window, window2 in
            (instances[window.owningApplication?.processID ?? 0] ?? 0) < (instances[window2.owningApplication?.processID ?? 0] ?? 0)
        }
        if !OBSManager.shared.acted {
            OBSManager.shared.storeWindowIDs(info: availableWindows.map { (instances[$0.owningApplication?.processID ?? 0] ?? 0, $0.windowID) })
        }
        for window in availableWindows {
            filters.append(SCContentFilter(desktopIndependentWindow: window))
            print("Appended filter: \(window.displayName) \(window.owningApplication?.processID ?? 0)")
        }

        return filters
    }

    private var streamConfiguration: SCStreamConfiguration {

        let streamConfig = SCStreamConfiguration()

        // Configure audio capture.
        streamConfig.capturesAudio = false
        streamConfig.showsCursor = false
        streamConfig.excludesCurrentProcessAudio = isAppAudioExcluded
        streamConfig.scalesToFit = true

        // Configure the window content width and height.
        streamConfig.width = 860
        streamConfig.height = 495

        // Set the capture interval at 15 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 15)

        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 6

        return streamConfig
    }

    /// - Tag: GetAvailableContent
    private func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
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
            .filter({ $0.displayName.contains( "Minecraft") && shortcutManager.instanceIDs.contains($0.owningApplication?.processID ?? 0) })
    }
}

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case (.some(let application), .some(let title)):
            return "\(application.applicationName): \(title)"
        case (.none, .some(let title)):
            return title
        case (.some(let application), .none):
            return "\(application.applicationName): \(windowID)"
        default:
            return ""
        }
    }
}

extension SCDisplay {
    var displayName: String {
        "Display: \(width) x \(height)"
    }
}

