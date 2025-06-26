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
    var isGameplayMode: Bool = false
    var keybind: Binding<Keybinding>?

    @Binding var x: Int?
    @Binding var y: Int?
    @Binding var width: Int?
    @Binding var height: Int?
    @ObservedObject var trackingManager = TrackingManager.shared

    private var invalidDimension: Bool {
        return width == nil || height == nil
    }

    private var containsDimensions: Bool {
        return (width ?? 0) > 0 || (height ?? 0) > 0
    }

    private var insideWindowFrame: Bool {
        return WindowController.dimensionsInBounds(width: width, height: height)
    }

    private var boundlessWarning: Bool {
        return !insideWindowFrame
            && TrackingManager.shared.getValues(\.info.isBoundless).contains(false)
    }

    private var hasResetDimensions: Bool {
        return (Settings[\.mode].baseWidth ?? 0) > 0 && (Settings[\.mode].baseHeight ?? 0) > 0
    }

    var body: some View {
        SettingsCardView {
            Form {
                VStack(spacing: 8) {
                    VStack(spacing: 3) {
                        Text("\(name) Mode")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(
                            .init(
                                "\(description)\n\(boundlessWarning ? "[This Dimension requires the BoundlessWindow Mod!](https://github.com/Slackow/BoundlessWindow)" : "")"
                            )
                        )
                        .tint(.orange)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.gray)
                        .padding(.trailing, 2)

                    }

                    HStack(spacing: 24) {
                        HStack {
                            TextField("W", value: $width, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .foregroundStyle(.primary)
                                .frame(width: 80)

                            TextField("H", value: $height, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .foregroundStyle(.primary)
                                .frame(width: 80)
                        }

                        HStack {
                            TextField("X", value: $x, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)

                            TextField("Y", value: $y, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 3)
                    .padding(.bottom, 8)

                    HStack {
                        if !isGameplayMode && !hasResetDimensions && containsDimensions {
                            Text("Missing Gameplay Dimensions")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .fontWeight(.semibold)
                        }

                        if let keybind {
                            KeybindingView(keybinding: keybind)
                        }

                        Button(action: copyVisibleFrame) {
                            Text("Copy Monitor")
                        }

                        Button(action: centerWindows) {
                            Text("Center")
                        }
                        .disabled(invalidDimension)

                        Button(action: tryDimension) {
                            Text("Try")
                        }.disabled(invalidDimension || trackingManager.trackedInstances.isEmpty)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .animation(.easeInOut, value: hasResetDimensions)
            .animation(.easeInOut, value: containsDimensions)
            .animation(.easeInOut, value: boundlessWarning)
        }
    }

    private func tryDimension() {
        guard let width, let height else { return }

        trackingManager.trackedInstances.forEach { inst in
            ShortcutManager.shared.resize(
                pid: inst.pid, x: x.map(CGFloat.init), y: y.map(CGFloat.init),
                width: CGFloat(width), height: CGFloat(height))
        }
    }

    private func copyVisibleFrame() {
        if let s = NSScreen.main?.visibleFrame.size {
            self.width = Int(s.width)
            self.height = Int(s.height)
            self.x = 0
            self.y = 0
        }
    }

    private func centerWindows() {
        if let s = NSScreen.main?.frame.size,
            let width, let height
        {
            x = (Int(s.width) - width) / 2
            y = (Int(s.height) - height) / 2
        }
    }
}

#Preview {
    VStack {
        @AppSettings(\.mode)
        var mode
        ModeCardView(
            name: "Wide", description: "None", x: $mode.wideX, y: $mode.wideY,
            width: $mode.wideWidth, height: $mode.wideHeight)
    }
    .padding(20)
}
