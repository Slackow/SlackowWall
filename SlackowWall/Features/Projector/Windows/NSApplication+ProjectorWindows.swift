//
//  NSApplication+ProjectorWindows.swift
//  SlackowWall
//
//  Created by Andrew on 6/12/26.
//

import AppKit
import SwiftUI

extension NSApplication {
    @MainActor
    func openProjectorWindow(_ id: SWWindowID) {
        guard let configuration = ProjectorWindowConfiguration(id: id) else { return }

        let window: ProjectorWindow
        if let existingWindow = ProjectorWindowStore.window(for: id) {
            window = existingWindow
        } else {
            getWindow(id)?.close()
            window = ProjectorWindow(
                contentRect: configuration.frame,
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.contentMinSize = configuration.minSize
            window.minSize = configuration.frameMinSize
            window.identifier = NSUserInterfaceItemIdentifier(id.rawValue)
            window.title = configuration.title
            window.contentViewController = NSHostingController(rootView: configuration.content)
            window.setFrameAutosaveName(configuration.frameAutosaveName)
            window.setFrameUsingName(configuration.frameAutosaveName, force: false)
            ProjectorWindowStore.setWindow(window, for: id)
        }

        window.contentMinSize = configuration.minSize
        window.minSize = configuration.frameMinSize
        window.level = configuration.isFloating ? .floating : .normal
        setTitleBarVisibility(id, isHidden: configuration.isTitleBarHidden, noReposition: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private enum ProjectorWindowStore {
    @MainActor
    private static var windows: [SWWindowID: ProjectorWindow] = [:]

    @MainActor
    static func window(for id: SWWindowID) -> ProjectorWindow? {
        windows[id]
    }

    @MainActor
    static func setWindow(_ window: ProjectorWindow, for id: SWWindowID) {
        windows[id] = window
    }
}

private struct ProjectorWindowConfiguration {
    let id: SWWindowID
    let title: String
    let minSize: CGSize
    let defaultSize: CGSize
    let content: AnyView
    let isFloating: Bool
    let isTitleBarHidden: Bool

    var frameAutosaveName: String {
        id.rawValue
    }

    var frameMinSize: CGSize {
        let contentRect = CGRect(origin: .zero, size: minSize)
        return NSWindow.frameRect(
            forContentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable]
        ).size
    }

    var frame: CGRect {
        guard let screenFrame = NSScreen.main?.visibleFrame else {
            return CGRect(origin: .zero, size: defaultSize)
        }

        let origin: CGPoint
        switch id {
            case .eyeProjector:
                origin = CGPoint(
                    x: screenFrame.maxX - defaultSize.width,
                    y: screenFrame.midY - defaultSize.height / 2
                )
            case .pieProjector:
                origin = CGPoint(
                    x: screenFrame.midX - defaultSize.width / 2,
                    y: screenFrame.minY
                )
            default:
                origin = .zero
        }

        return CGRect(origin: origin, size: defaultSize)
    }

    init?(id: SWWindowID) {
        let utility = Settings[\.utility]
        self.id = id

        switch id {
            case .eyeProjector:
                title = "Eye Projector"
                minSize = CGSize(width: 300, height: 200)
                defaultSize = CGSize(width: 600, height: 400)
                content = AnyView(EyeProjectorWindowView().frame(minWidth: 300, minHeight: 200))
                isFloating = utility.eyeProjectorAlwaysOnTop
                isTitleBarHidden = utility.eyeProjectorTitleBarHidden
            case .pieProjector:
                title = "Pie Projector"
                minSize = CGSize(width: 384, height: 384)
                defaultSize = CGSize(width: 384, height: 384)
                content = AnyView(PieProjectorWindowView().frame(minWidth: 384, minHeight: 384))
                isFloating = utility.pieProjectorAlwaysOnTop
                isTitleBarHidden = utility.pieProjectorTitleBarHidden
            default:
                return nil
        }
    }
}
