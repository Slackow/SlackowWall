//
//  ScreenRecorder.swift
//  SlackowWall
//
//  Created by Dominic Thompson on 1/12/23.
//

import Foundation
import ScreenCaptureKit
import Combine
import OSLog
import SwiftUI

@MainActor
class ScreenRecorder: ObservableObject {

    /// The supported capture types.
    enum CaptureType {
        case display
        case window
    }

    private let logger = Logger()
    private var shortcutManager = ShortcutManager.shared

    @Published var isRunning = false

    // MARK: - Video Properties
    @Published var captureType: CaptureType = .window {
        didSet {
            updateEngine()
        }
    }

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

    @Published var contentSize = CGSize(width: 1, height: 1)
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
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                return true
            } catch {
                return false
            }
        }
    }

    func monitorAvailableContent() async {
        guard !isSetup else {
            return
        }

        // Refresh the lists of capturable content.
        await self.refreshAvailableContent()

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

        for filter in contentFilters {
            let capturePreview = CapturePreview()
            capturePreviews.append(capturePreview)
            Task {
                do {
                    for try await frame in captureEngine.startCapture(configuration: config, filter: filter) {
                        capturePreview.updateFrame(frame)
                        if contentSize != frame.size {
                            // Update the content size if it changed.
                            contentSize = frame.size
                        }
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

    /// - Tag: UpdateCaptureConfig
    private func updateEngine() {
        guard isRunning else {
            return
        }
        Task {
            for filter in contentFilters {
                await captureEngine.update(configuration: streamConfiguration, filter: filter)
            }
        }
    }

    /// - Tag: UpdateFilter
    private var contentFilters: [SCContentFilter] {
        var filters: [SCContentFilter] = []
        var x = ShortcutManager.shared.instanceNums
        //print ("\(availableWindows.map{$0.owningApplication?.processID ?? 0})")
        availableWindows.sort { window, window2 in
            (x[window.owningApplication?.processID ?? 0] ?? 0) < (x[window2.owningApplication?.processID ?? 0] ?? 0) }


        //print ("\(availableWindows.map{$0.owningApplication?.processID ?? 0})")
        for window in availableWindows {
            // Create a content filter that includes a single window.
            filters.append(SCContentFilter(desktopIndependentWindow: window))
        }

        return filters
    }

    private var streamConfiguration: SCStreamConfiguration {

        let streamConfig = SCStreamConfiguration()

        // Configure audio capture.
        streamConfig.capturesAudio = false
        streamConfig.showsCursor = false
        streamConfig.excludesCurrentProcessAudio = isAppAudioExcluded

        // Configure the display content width and height.
        if captureType == .display, let display = selectedDisplay {
            streamConfig.width = display.width * scaleFactor
            streamConfig.height = display.height * scaleFactor
        }

        // Configure the window content width and height.
        if captureType == .window, let window = selectedWindow {
            streamConfig.width = Int(window.frame.width)
            streamConfig.height = Int(window.frame.height)
        }

        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 15)

        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5

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
        windows
                // Remove all windows that are not Minecraft Instances
                .filter({ shortcutManager.instanceIDs.contains($0.owningApplication?.processID ?? 0) })
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

