//
//  MinecraftAdjusterFixSheet.swift
//  SlackowWall
//
//  Created by Andrew on 2/13/26.
//

import SwiftUI

struct MinecraftAdjusterFixSheet: View {
    @Environment(\.dismiss) private var dismiss

    let instance: TrackedInstance
    let results: MinecraftAdjuster.Results

    @State private var isFixing: Bool = false
    @State private var fixError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fixing Minecraft Settings")
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
                                    idx, result in
                                    settingRow(for: result)

                                    if idx < results.breaking.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            Text("This will close the instance while updating your settings.")
                .font(.callout)
                .foregroundStyle(.secondary)

            ForEach(results.breaking.compactMap(\.id.warning), id: \.self) { description in
                Text(.init(description))
                    .font(.callout)
                    .foregroundStyle(.orange)
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
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isFixing)
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 340)
    }

    private func settingRow(for result: MinecraftAdjuster.MinecraftResult) -> some View {
        let oldValue = result.id.valueName(result.oldValue)
        let newValue = result.id.valueName(result.newValue)
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(result.id.name)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 0) {

                    Text(.init("[\(oldValue)](0)"))
                        .tint(.red)
                    Text(" → ")
                    Text(.init("[\(newValue)](0)"))
                        .tint(.green)
                }
            }

            if let description = result.id.description {
                Text(.init(description))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func applyFixes() {
        fixError = nil
        guard !instance.info.path.isEmpty else {
            fixError = "Unable to locate the instance folder."
            return
        }
        isFixing = true

        Task.detached(priority: .utility) { [instance] in
            await MinecraftAdjuster().fix(instance: instance)
            await MainActor.run {
                isFixing = false
                instance.refreshBoatEyeStatus()
                dismiss()
            }
        }
    }
}
