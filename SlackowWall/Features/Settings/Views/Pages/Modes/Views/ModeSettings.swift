//
//  ModeSettings.swift
//  SlackowWall
//
//  Created by Kihron on 7/25/24.
//

import SwiftUI

struct ModeSettings: View {
    @StateObject private var viewModel = ModeSettingsViewModel()
    @State private var showingResizeBackgroundFileImporter = false

    @AppSettings(\.mode) private var settings
    @AppSettings(\.keybinds) private var keybinds
    @AppSettings(\.utility) private var utility

    var body: some View {
        SettingsPageView(title: "Window Resizing", shouldDisableFocus: false) {
            SettingsLabel(
                title: "Dimensions",
                description:
                    "The dimensions of the game windows in different cases.\nCurrent monitor size: [\(viewModel.screenSize)](0), subtracting menu bar and dock: [\(viewModel.visibleScreenSize)](0)."
            )
            .tint(.orange)
            .allowsHitTesting(false)
            .contentTransition(.numericText())
            .animation(.smooth, value: viewModel.visibleScreenSize)
            .padding(.bottom, -6)

            VStack {
                if viewModel.multipleOutOfBounds {
                    Text(
                        .init(
                            "More than one dimension out of bounds is illegal, this will invalidate your run!"
                        )
                    )
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.red)
                }
                if viewModel.anyToolscreen {
                    Text(
                        .init(
                            "Tux Injector/Linuxscreen detected, use their builtin window resizing instead."
                        )
                    )
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.red)
                }
            }
            .animation(
                .easeInOut.delay(viewModel.multipleOutOfBounds ? 0.3 : 0),
                value: viewModel.multipleOutOfBounds)

            ModeCardView(
                name: "Gameplay",
                description:
                    "The size of the game while you are in an instance, required for other modes to work.\nOptional Keybind goes directly to gameplay, other keybinds toggle their sizes.",
                actualDimensions: Settings[\.self].baseDimensions,
                isGameplayMode: true, isExpanded: true, keybind: $keybinds.baseGKey,
                resizeBackgroundAction: .hide,
                posHints: ("", ""),
                mode: $settings.baseMode
            )

            ModeCardView(
                name: "Tall",
                description: "Tall is generally used for eye measuring or zoom.",
                actualDimensions: Settings[\.self].tallDimensions(
                    for: TrackingManager.shared.trackedInstances.first),
                keybind: $keybinds.tallGKey,
                resizeBackgroundAction: .show,
                mode: $settings.tallMode
            )

            ModeCardView(
                name: "Thin",
                description:
                    "Thin is generally used for buried treasures, preemptive, and/or e-ray.",
                actualDimensions: Settings[\.self].thinDimensions,
                keybind: $keybinds.thinGKey,
                resizeBackgroundAction: .show,
                mode: $settings.thinMode
            )

            ModeCardView(
                name: "Wide",
                description: "Wide is generally used for seeing further with planar fog.",
                actualDimensions: Settings[\.self].wideDimensions,
                keybind: $keybinds.planarGKey,
                resizeBackgroundAction: .show,
                mode: $settings.wideMode
            )

            ModeCardView(
                name: "Reset",
                description:
                    "Reset is used for wall mode, and is used to make your instances wider so you can see more on the preview.",
                actualDimensions: Settings[\.self].resetDimensions,
                resizeBackgroundAction: .hide,
                posHints: ("", ""),
                mode: $settings.resetMode
            )

            SettingsLabel(
                title: "Miscellaneous"
            )
            SettingsCardView {
                VStack {
                    SettingsToggleView(
                        title: "Resize Background",
                        description:
                            "Shows a selected image behind Minecraft while Tall, Thin, or Wide mode is active.",
                        option: $settings.resizeBackgroundEnabled
                    )
                    .onChange(of: settings.resizeBackgroundEnabled) { isEnabled in
                        if !isEnabled {
                            ResizeBackgroundManager.shared.hide()
                        }
                    }

                    Divider()

                    SettingsToggleView(
                        title: "Auto-Background Appearance",
                        description:
                            "Automatically shows the background in Tall, Thin, and Wide modes, then hides it in Gameplay or Reset.",
                        option: $settings.resizeBackgroundAutoAppearance
                    )
                    .disabled(!settings.resizeBackgroundEnabled)
                    .onChange(of: settings.resizeBackgroundAutoAppearance) { isEnabled in
                        if !isEnabled {
                            ResizeBackgroundManager.shared.hide()
                        }
                    }

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Background Image",
                            description: settings.resizeBackgroundImage?.lastPathComponent
                                ?? "No image selected.",
                            font: .body)

                        if let image = resizeBackgroundPreviewImage {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 42, height: 42)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }

                        if settings.resizeBackgroundImage != nil {
                            Button {
                                settings.resizeBackgroundImage = nil
                                ResizeBackgroundManager.shared.hide()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(settings.resizeBackgroundImage == nil ? "Select Image" : "Change") {
                            showingResizeBackgroundFileImporter = true
                        }
                    }
                    .disabled(!settings.resizeBackgroundEnabled)
                    .fileImporter(
                        isPresented: $showingResizeBackgroundFileImporter,
                        allowedContentTypes: [.image],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                            case .success(let urls):
                                settings.resizeBackgroundImage = urls.first
                                ResizeBackgroundManager.shared.hide()
                            case .failure(let error):
                                LogManager.shared.appendLog(
                                    "Failed to select resize background image",
                                    error.localizedDescription)
                        }
                    }

                    Divider()

                    HStack {
                        SettingsLabel(title: "Background Opacity", font: .body)
                        Text("\(Int(settings.resizeBackgroundOpacity * 100))%")
                        Slider(value: $settings.resizeBackgroundOpacity, in: 0...1)
                            .frame(width: 200, height: 25)
                    }
                    .disabled(!settings.resizeBackgroundEnabled)

                    Divider()

                    HStack {
                        SettingsLabel(
                            title: "Toggle Tall Mode (No Modifiers)",
                            description:
                                "Enter tall mode without activating projector/lowering sens, useful for eye zoom preemptive.",
                            font: .body)
                        KeybindingView(keybinding: \.tallNoSensGKey)
                    }
                    Divider()
                    SettingsToggleView(
                        title: "Don't resize while in a GUI",
                        description: "Disables resizing hotkeys while in chat or inventory.",
                        infoBlurb: "Requires State Output Mod",
                        option: $settings.blockResizeInGUI
                    )
                }
            }
        }
        .animation(
            .smooth.delay(viewModel.multipleOutOfBounds ? 0 : 0.3),
            value: viewModel.multipleOutOfBounds
        )
    }

    private var resizeBackgroundPreviewImage: NSImage? {
        settings.resizeBackgroundImage.flatMap { NSImage(contentsOf: $0) }
    }
}

#Preview {
    ScrollView {
        ModeSettings()
            .padding()
    }
}
