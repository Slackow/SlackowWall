//
//  NinbotFixSheet.swift
//  SlackowWall
//
//  Created by Andrew on 2/8/26.
//

import SwiftUI

struct NinbotFixSheet: View {
    @Environment(\.dismiss) private var dismiss

    let instance: TrackedInstance
    let results: NinjabrainAdjuster.Results

    @State private var selectedRecommended: Set<NinjabrainAdjuster.NinBotResult>
    @State private var isFixing: Bool = false
    @State private var fixError: String?
    @State private var retinoWarningAcknowledged: Bool = false

    init(instance: TrackedInstance, results: NinjabrainAdjuster.Results) {
        self.instance = instance
        self.results = results
        _selectedRecommended = State(initialValue: Set(results.recommend))
    }

    var body: some View {
        let screenScale = NSScreen.factor
        let hasRetino = instance.hasMod(.retino)
        let resolutionHeight =
            if case .some(.float(let h)) = results.breaking.first(where: { $0.id == .resolution_height })?.newValue {
                h
            } else {
                Float32(16384.0)
            }
        let showResolutionCrashError = resolutionHeight > 16384
        let showRetinoWarning = hasRetino && screenScale > 1
        let canApplyFixes =
            !showResolutionCrashError
            && (!showRetinoWarning || retinoWarningAcknowledged)

        VStack(alignment: .leading, spacing: 12) {
            Text("Fixing NinjabrainBot Settings")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Breaking (\(results.breaking.count)) - BoatEye will not work until these are fixed.")
                    .font(.headline)

                SettingsCardView {
                    Group {
                        if results.breaking.isEmpty {
                            Text("No breaking issues found.")
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(results.breaking.enumerated()), id: \.offset) {
                                    idx, setting in
                                    settingRow(for: setting)

                                    if idx < results.breaking.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if !results.recommend.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommended (\(results.recommend.count))")
                        .font(.headline)

                    SettingsCardView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(results.recommend.enumerated()), id: \.offset) {
                                idx, setting in
                                Toggle(isOn: binding(for: setting)) {
                                    settingRow(for: setting)
                                }

                                if idx < results.recommend.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            Text("This will close NinjabrainBot while updating your settings.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if showResolutionCrashError || showRetinoWarning {
                VStack(alignment: .leading, spacing: 8) {
                    if showResolutionCrashError {
                        Text(
                            "Error: Your calculated resolution height (\(Int(resolutionHeight))) is above 16384. \nYou should remove your \"Tall Mode Height\" setting in SlackowWall,\notherwise Minecraft will crash when entering tall mode."
                        )
                        .font(.callout)
                        .foregroundStyle(.red)
                    }
                    if showRetinoWarning {
                        Text(
                            """
                            Warning: The retiNO mod is reducing your maximum usable resolution height, decreasing your \
                            accuracy.
                            Remove it, or learn more and find alternatives: \
                            [here](https://docs.google.com/document/d/\
                            1gD_ZZYFCEOJxImyfpUxLHGn702moP9I69-46fhWe9QM\
                            /edit), \
                            or dismiss this warning.
                            """
                        )
                        .font(.callout)
                        .foregroundStyle(.orange)

                        if !showResolutionCrashError {
                            Toggle("Got it, ignore", isOn: $retinoWarningAcknowledged)
                                .toggleStyle(.checkbox)
                                .controlSize(.small)
                        }
                    }
                }
                .font(.callout)
            }

            HStack {
                if let fixError {
                    Text(fixError)
                        .foregroundStyle(.red)
                }

                Spacer()

                Button("Cancel", role: .cancel) {
                    dismiss()
                }

                Button(isFixing ? "Fixing..." : "Apply Fixes") {
                    applyFixes()
                }
                .if(canApplyFixes) { $0.buttonStyle(.borderedProminent) }
                //                .keyboardShortcut(.defaultAction)
                .disabled(isFixing || !canApplyFixes)

            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 420)
    }

    private func settingRow(for setting: NinjabrainAdjuster.NinBotResult) -> some View {
        let oldValue = setting.id.valueName(setting.oldValue)
        let newValue = setting.id.valueName(setting.newValue)
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(setting.id.name)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 0) {
                    Text(.init("[\(oldValue)](0)"))
                        .tint(.red)
                    Text(" → ")
                    Text(.init("[\(newValue)](0)"))
                        .tint(.green)
                }
                .allowsHitTesting(false)
            }
            if let description = setting.id.description {
                Text(
                    "\(description)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func binding(for setting: NinjabrainAdjuster.NinBotResult) -> Binding<Bool> {
        Binding(
            get: { selectedRecommended.contains(setting) },
            set: { isOn in
                if isOn {
                    selectedRecommended.insert(setting)
                } else {
                    selectedRecommended.remove(setting)
                }
            }
        )
    }

    private func buildFixFilter() -> [NinjabrainAdjuster.NinBotSetting] {
        var filter = results.breaking
        for setting in selectedRecommended where !filter.contains(setting) {
            filter.append(setting)
        }
        return filter.map(\.id)
    }

    private func applyFixes() {
        let screenScale = NSScreen.factor
        let hasRetino = instance.hasMod(.retino)
        let isLoDPI = hasRetino || screenScale == 1
        let resolutionHeight = Float32(
            Settings[\.self].tallDimensions(for: instance).1 * (isLoDPI ? 1 : 2))
        let showResolutionCrashError = resolutionHeight > 16384
        let showRetinoWarning = hasRetino && screenScale > 1
        guard
            !showResolutionCrashError
                && (!showRetinoWarning || retinoWarningAcknowledged)
        else { return }
        fixError = nil
        isFixing = true
        let fixFilter = buildFixFilter()

        DispatchQueue.global(qos: .utility).async {
            do {
                try NinjabrainAdjuster.fix(instance: instance, fixFilter: fixFilter)
                DispatchQueue.main.async {
                    isFixing = false
                    instance.refreshBoatEyeStatus()
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isFixing = false
                    fixError = "Failed to apply fixes."
                }
                LogManager.shared.appendLog("Failed to fix NinjabrainBot settings:", error)
            }
        }
    }
}
