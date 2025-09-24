//
//  WindowController.swift
//  SlackowWall
//
//  Created by Kihron on 7/21/24.
//

import Network
import SwiftUI

class WindowController {
    private init() {}

    static func focusWindow(_ pid: pid_t) {
        NSRunningApplication(processIdentifier: pid)?.activate(options: [
            .activateAllWindows /*.activateIgnoringOtherApps, (For macOS 13.)*/
        ])
    }

    static func hideWindows(_ pids: [pid_t]) {
        for pid in pids {
            let app = AXUIElementCreateApplication(pid)
            var error: AXError = AXError.success
            error = AXUIElementSetAttributeValue(
                app, kAXHiddenAttribute as CFString, kCFBooleanTrue)
            if error != .success {
                LogManager.shared.appendLog(
                    "Error setting visibility attribute for \(pid): \(error)")
            }
        }
    }

    static func unhideWindows(_ pids: [pid_t]) {
        for pid in pids {
            let app = AXUIElementCreateApplication(pid)
            var error: AXError = AXError.success
            error = AXUIElementSetAttributeValue(
                app, kAXHiddenAttribute as CFString, kCFBooleanFalse)
            if error != .success {
                LogManager.shared.appendLog(
                    "Error setting visibility attribute for \(pid): \(error)")
            }
        }
    }

    static func getWindowTitle(pid: pid_t) -> String? {
        return getWindowProperty(pid: pid, attribute: kAXTitleAttribute) as? String
    }

    static func getWindowPosition(pid: pid_t) -> CGPoint? {
        if let posValue = getWindowProperty(pid: pid, attribute: kAXPositionAttribute) {
            var pos = CGPoint.zero
            if AXValueGetValue(posValue as! AXValue, AXValueType.cgPoint, &pos) {
                return pos
            }
        }
        return nil
    }

    static func getWindowSize(pid: pid_t) -> CGSize? {
        if let sizeValue = getWindowProperty(pid: pid, attribute: kAXSizeAttribute) {
            var size = CGSize.zero
            if AXValueGetValue(sizeValue as! AXValue, AXValueType.cgSize, &size) {
                return size
            }
        }
        return nil
    }

    static func dimensionsInBounds(width: Int?, height: Int?) -> Bool {
        guard let screen = NSScreen.primary?.frame else { return true }
        let screenWidth = Int(screen.width)
        let screenHeight = Int(screen.height)

        return screenWidth >= (width ?? 0) && screenHeight >= (height ?? 0)
    }

    private static func getWindowProperty(pid: pid_t, attribute: String) -> AnyObject? {
        let appRef = AXUIElementCreateApplication(pid)
        var value: AnyObject?

        if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)
            == .success, let windows = value as? [AXUIElement]
        {
            for window in windows {
                var titleValue: AnyObject?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
                guard let title = titleValue as? String, title != "Window" else { continue }

                var propertyValue: AnyObject?
                if AXUIElementCopyAttributeValue(window, attribute as CFString, &propertyValue)
                    == .success
                {
                    return propertyValue
                }
            }
        }
        return nil
    }

    private static func getWindowAttributes(window: AXUIElement) -> (
        title: String?, pos: CGPoint, size: CGSize
    )? {
        var titleValue: AnyObject?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        guard let title = titleValue as? String else { return nil }

        var posValue: AnyObject?
        var sizeValue: AnyObject?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posValue)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        guard let posValue = posValue, let sizeValue = sizeValue else { return nil }

        var pos = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, AXValueType.cgPoint, &pos)
        AXValueGetValue(sizeValue as! AXValue, AXValueType.cgSize, &size)

        return (title, pos, size)
    }

    static func sendResizeCommand(
        instance: TrackedInstance, x: Int?, y: Int?, width: Int?, height: Int?
    ) {
        let port = instance.info.port
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            LogManager.shared.appendLog("Invalid port value: \(port)")
            return
        }
        func un(_ n: Int?) -> String { return n?.description ?? "-" }
        let command = "set \(un(x)) \(un(y)) \(un(width)) \(un(height))\n"

        // Create an NWConnection to localhost on the instance's port.
        let connection = NWConnection(host: .init("127.0.0.1"), port: nwPort, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
                case .failed(let reason), .waiting(let reason):
                    LogManager.shared.appendLog("Connection state: \(state), \(reason)")
                default: break
            }
        }

        connection.start(queue: DispatchQueue.global())
        connection.send(
            content: command.data(using: .utf8),
            completion: .contentProcessed({ error in
                if let error {
                    LogManager.shared.appendLog("Error sending resize command: \(error)")
                    connection.cancel()
                    return
                } else {
                    LogManager.shared.appendLog(
                        "Resize command sent: \(command.trimmingCharacters(in: .newlines))")
                }
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) {
                    data, context, isComplete, error in
                    if let error {
                        LogManager.shared.appendLog("Receive error: \(error)")
                    } else if let data, let response = String(data: data, encoding: .utf8) {
                        LogManager.shared.appendLog(
                            "Received response: \(response.trimmingCharacters(in: .newlines))")
                    } else {
                        LogManager.shared.appendLog("Connection closed by remote")
                    }

                    // 3) Close once we’ve gotten (or failed to get) that response
                    connection.cancel()
                }
            }))
    }

    static func modifyWindow(
        pid: pid_t, x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        let appRef = AXUIElementCreateApplication(pid)
        var value: AnyObject?

        if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)
            == .success, let windows = value as? [AXUIElement]
        {
            for window in windows {
                if let (title, pos, size) = getWindowAttributes(window: window), title != "Window" {
                    var newPosition = pos
                    if let x, let y {
                        newPosition = CGPoint(x: x, y: y)
                    } else {
                        newPosition = CGPoint(x: CGFloat(x ?? 0), y: CGFloat(y ?? 0))
                    }

                    var newSize = size
                    if let width, let height, width > 0, height > 0 {
                        newSize = CGSize(width: width, height: height)
                    }

                    if let positionRef = AXValueCreate(AXValueType.cgPoint, &newPosition) {
                        AXUIElementSetAttributeValue(
                            window, kAXPositionAttribute as CFString, positionRef)
                    }
                    if let sizeRef = AXValueCreate(AXValueType.cgSize, &newSize), width != nil,
                        height != nil, width! > 0, height! > 0
                    {
                        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeRef)
                    }
                }
            }
        }
    }
}
