//
//  MouseSensitivityController.swift
//  SlackowWall
//
//  Created by Andrew on 6/1/25.
//

import CoreGraphics
/// Scales raw HID deltas before the cursor moves.
/// Call `start(factor:)` with a factor < 1 to slow the mouse,
/// 1.0 to restore normal speed, or `stop()` to detach completely.
import Foundation

class MouseSensitivityManager: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    @Published var isActive = false

    private var sensitivityFactor: Double = 1.0

    private var accumulatedDeltaX: Double = 0
    private var accumulatedDeltaY: Double = 0

    @MainActor static let shared = MouseSensitivityManager()

    func setSensitivityFactor(factor: Double, if: Bool? = nil) {
        if isActive { stopReducingSensitivity() }
        guard `if` ?? Settings[\.utility].sensitivityScaleEnabled else {
            LogManager.shared.appendLog(
                "Sensitivity Scale Disabled \(Settings[\.utility].sensitivityScaleEnabled), attempted to set to \(factor)"
            )
            return
        }

        LogManager.shared.appendLog("Changing Sensitivity Factor to", factor)
        let factor = (0.05...100).clamped(value: factor)
        self.sensitivityFactor = factor
        if factor == 1.0 { return }

        // Create event tap for mouse moved events
        let eventMask =
            0
            | (1 << CGEventType.mouseMoved.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.rightMouseDragged.rawValue)
            | (1 << CGEventType.otherMouseDragged.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<MouseSensitivityManager>.fromOpaque(refcon)
                    .takeUnretainedValue()
                return manager.handleMouseEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            LogManager.shared.appendLog("Failed to create event tap")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isActive = true
    }

    func stopReducingSensitivity() {
        LogManager.shared.appendLog("Disabling Sensitivity Factor")
        guard isActive else { return }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isActive = false
    }

    private func handleMouseEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent)
        -> Unmanaged<CGEvent>?
    {
        let deltaX = event.getIntegerValueField(.mouseEventDeltaX)
        let deltaY = event.getIntegerValueField(.mouseEventDeltaY)

        guard deltaX != 0 || deltaY != 0 else {
            return Unmanaged.passUnretained(event)
        }

        accumulatedDeltaX += Double(deltaX) * sensitivityFactor
        accumulatedDeltaY += Double(deltaY) * sensitivityFactor

        let outputDeltaX = Int64(accumulatedDeltaX.rounded())
        let outputDeltaY = Int64(accumulatedDeltaY.rounded())

        accumulatedDeltaX -= Double(outputDeltaX)
        accumulatedDeltaY -= Double(outputDeltaY)

        event.setIntegerValueField(.mouseEventDeltaX, value: outputDeltaX)
        event.setIntegerValueField(.mouseEventDeltaY, value: outputDeltaY)

        return Unmanaged.passUnretained(event)
    }

    deinit {
        stopReducingSensitivity()
    }
}
