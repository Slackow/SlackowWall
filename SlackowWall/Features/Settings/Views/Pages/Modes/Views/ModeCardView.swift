//
//  ModeCardView.swift
//  SlackowWall
//
//  Created by Andrew on 4/28/24.
//

import SwiftUI

struct ModeCardView: View {

    var name: String
    var description: String
    var actualDimensions: (CGFloat?, CGFloat?, CGFloat?, CGFloat?)
    var isGameplayMode: Bool = false
    @State var isExpanded: Bool = false
    var keybind: Binding<Keybinding>?

    var posHints: (String, String) = ("--", "--")
    @Binding var mode: Preferences.SizeMode
    @ObservedObject var trackingManager = TrackingManager.shared

    private var containsDimensions: Bool {
        actualDimensions.0 != nil && actualDimensions.1 != nil
    }

    private var insideWindowFrame: Bool {
        WindowController.dimensionsInBounds(width: Int(actualDimensions.0 ?? 0), height: Int(actualDimensions.1 ?? 0))
    }

    private var boundlessWarning: Bool {
        return !insideWindowFrame
            && TrackingManager.shared.getValues(\.info.isBoundless).contains(false)
    }

    private var hasResetDimensions: Bool {
        return (Settings[\.mode].baseMode.width ?? 0) > 0 && (Settings[\.mode].baseMode.height ?? 0) > 0
    }
    
    private var dimensionSummary: String {
        let (w, h, x, y) = actualDimensions
        let text = "(\(w?.str ?? "--") x \(h?.str ?? "--"))\(x != nil || y != nil ? " @ (\(x?.str ?? "--"), \(y?.str ?? "--"))" : "")"
        if !containsDimensions {
            return "[\(text)](0)"
        }
        return text
    }

    var body: some View {
        SettingsCardView {
            Form {
                VStack(spacing: isExpanded ? 8 : 4) {
                    VStack(spacing: 3) {
                        HStack {
                            Text(.init("\(name) Mode\(isGameplayMode && !containsDimensions ? " [*](0)" : "")\(isExpanded ? "" : " -> \(dimensionSummary)")"))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .tint(.red)
                                .allowsHitTesting(false)
                            if !isGameplayMode {
                                Button(action: { isExpanded.toggle() }) {
                                    Image(systemName: isExpanded ? "chevron.down" : "chevron.left")
                                        .frame(width: 15, height: 15)
                                        .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .removeFocusOnTap()
                        HStack {
                            Text(
                                .init(
                                    "\(description)\n\(boundlessWarning ? "This Dimension requires the [BoundlessWindow Mod!](https://github.com/Slackow/BoundlessWindow)" : "")"
                                )
                            )
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.gray)
                            .padding(.trailing, 2)
                            if !isExpanded {
                                actionRow
                            }
                        }

                    }
                    if isExpanded {
                        HStack(spacing: 24) {
                            HStack {
                                TextField(
                                    "W", value: $mode.width, format: .number.grouping(.never),
                                    prompt: Text(actualDimensions.0?.str ?? "")
                                )
                                .textFieldStyle(.roundedBorder)
                                .foregroundStyle(.primary)
                                .frame(width: 80)
                                
                                TextField(
                                    "H", value: $mode.height, format: .number.grouping(.never),
                                    prompt: Text(actualDimensions.1?.str ?? "")
                                )
                                .textFieldStyle(.roundedBorder)
                                .foregroundStyle(.primary)
                                .frame(width: 80)
                            }
                            
                            HStack {
                                TextField(
                                    "X", value: $mode.x, format: .number.grouping(.never),
                                    prompt: Text(actualDimensions.2?.str ?? posHints.0)
                                )
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                
                                TextField(
                                    "Y", value: $mode.y, format: .number.grouping(.never),
                                    prompt: Text(actualDimensions.3?.str ?? posHints.1)
                                )
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 3)
                        .padding(.bottom, 8)
                        actionRow
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .animation(.easeInOut, value: hasResetDimensions)
            .animation(.easeInOut, value: containsDimensions)
            .animation(.easeInOut, value: boundlessWarning)
        }
    }
    
    var actionRow: some View {
        HStack {
            if isGameplayMode {
                Button("Full Monitor", systemImage: "document.on.document", action: copyFrame)
                    .popoverLabel("Set Gameplay to take up the entire monitor")
                Button("Visible Frame", systemImage: "document.on.document", action: copyVisibleFrame)
                    .popoverLabel("Uses current screen, accounting for the Dock and Menu Bar")
            }
            
            if let keybind {
                KeybindingView(keybinding: keybind)
            }
            
            Button(action: tryDimension) {
                Text("Try")
            }.disabled(!containsDimensions)
        }
        .frame(alignment: .trailing)
    }

    private func tryDimension() {
        guard case let (.some(w), .some(h), x, y) = actualDimensions else { return }
        trackingManager.trackedInstances.forEach { inst in
            ShortcutManager.shared.resize(
                pid: inst.pid, x: x, y: y, width: w, height: h, force: true)
        }
    }

    private func copyFrame() {
        if let s = NSScreen.primary?.frame.size {
            self.mode.width = Int(s.width)
            self.mode.height = Int(s.height)
            self.mode.x = 0
            self.mode.y = 0
        }
    }
    private func copyVisibleFrame() {
        if let s = NSScreen.primary?.visibleFrame, let fullHeight = NSScreen.primary?.frame.height {
            self.mode.width = Int(s.size.width)
            self.mode.height = Int(s.size.height)
            self.mode.x = 0
            self.mode.y = Int(fullHeight - s.maxY)
        }
    }
}

private extension CGFloat {
    var str: String {
        Int(self).description
    }
}
