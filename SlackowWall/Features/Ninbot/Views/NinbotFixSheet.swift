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

    init(instance: TrackedInstance, results: NinjabrainAdjuster.Results) {
        self.instance = instance
        self.results = results
        _selectedRecommended = State(initialValue: Set(results.recommend))
    }

    var body: some View {
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
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isFixing)

            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 420)
    }

    private func settingRow(for setting: NinjabrainAdjuster.NinBotResult) -> some View {
        let oldValue = setting.id.valueName(setting.oldValue)
        let newValue = setting.id.valueName(setting.newValue)
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(setting.id.name)
                    .fontWeight(.semibold)
                Text("\(oldValue) → \(newValue)")
            }
            if let description = setting.id.description {
                Text(
                    "\(description.replacingOccurrences(of: "$n", with: newValue).replacingOccurrences(of: "$o", with: oldValue))"
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
        fixError = nil
        isFixing = true
        let fixFilter = buildFixFilter()

        DispatchQueue.global(qos: .utility).async {
            do {
                try NinjabrainAdjuster.fix(instance: instance, fixFilter: fixFilter)
                DispatchQueue.main.async {
                    isFixing = false
                    instance.refreshNinbotStatus()
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
