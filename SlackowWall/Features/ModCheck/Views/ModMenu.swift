//
//  ModMenu.swift
//  SlackowWall
//
//  Created by Kihron on 6/19/25.
//

import SwiftUI

struct ModMenu: View {
    @Environment(\.dismiss) private var dismiss

    var instance: TrackedInstance
    @StateObject var viewModel = ModListViewModel()

    @State var modsToUpdate: [(ModInfo, ModVersion)]?
    @State var legalModCount: Int?
    @State var isChecking: Bool = false
    @State var isConfirmationOpen: Bool = false
    @State var isUpToDateOpen: Bool = false
    @State var isFailedModListErrorOpen: Bool = false
    @State var failedToUpdate: [(ModInfo, ModVersion)]?
    @State var succeededToUpdate: [(ModInfo, ModVersion)]?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Mods - \(viewModel.mods.count)")
                .font(.title2)
                .fontWeight(.bold)

            SettingsCardView(padding: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.mods, id: \.filePath) { (mod: ModInfo) in
                            HStack {
                                Group {
                                    if let icon = viewModel.getModIcon(for: mod) {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } else {
                                        ZStack {
                                            Rectangle()
                                                .foregroundStyle(.gray)

                                            Text("N/A")
                                                .font(.title3)
                                                .foregroundStyle(.black)
                                        }
                                    }
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(.rect(cornerRadius: 5))

                                VStack(alignment: .leading) {
                                    let authorLine = mod.authors.map(\.name).joined(separator: ", ")
                                    HStack(spacing: 0) {
                                        Text(mod.name)
                                        if !authorLine.isEmpty {
                                            Text(" by " + authorLine)
                                                .foregroundStyle(.gray)
                                        }
                                        if mod.disabled == true {
                                            Text(" (disabled)")
                                                .foregroundStyle(.red)
                                        }
                                    }

                                    Text(mod.version)
                                        .font(.footnote)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .frame(height: 32)
                            .padding(.leading, 6)

                            if let idx = viewModel.mods.firstIndex(where: { $0.id == mod.id }),
                                idx < viewModel.mods.count - 1
                            {
                                Divider()
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack {
                Button(action: updateCheck) {
                    Text("Check for Updates (beta)")
                }
                .disabled(isChecking)
                Button(action: { dismiss() }) {
                    Text("Close")
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 500, height: 300)
        .task {
            viewModel.fetchMods(instance: instance)
        }
        .confirmationDialog(
            Text("Update \(modsToUpdate?.count ?? 0) mod(s)? (Closes MC)"),
            isPresented: $isConfirmationOpen,
            titleVisibility: .visible
        ) {
            Button("Update") {
                Task {
                    (succeededToUpdate, failedToUpdate) = await ModChecking.updateMods(
                        instance: instance, mods: modsToUpdate ?? [])
                    if let failedToUpdate, !failedToUpdate.isEmpty {
                        let successCount = succeededToUpdate?.count ?? 0
                        AlertManager.shared.dismissableError(
                            message:
                                "Updated \(successCount) mods. Failed to update \(failedToUpdate.map(\.0.id).sorted().joined(separator: ", "))"
                        )
                    }
                }
            }
            Button("Cancel", role: .cancel) { modsToUpdate = nil }
        } message: {
            Text("Update \(modsToUpdate?.map {$0.0.id}.sorted().joined(separator: ", ") ?? "")?")
        }
        .alert(
            "All \(legalModCount ?? 0) legal mods up to date!",
            isPresented: $isUpToDateOpen,
            actions: { Button("OK", role: .cancel) {} }
        )
        .alert(
            "Failed to fetch legal mod list",
            isPresented: $isFailedModListErrorOpen,
            actions: { Button("OK", role: .cancel) {} }
        )

    }

    func updateCheck() {
        isChecking = true
        Task {
            defer { isChecking = false }
            do {
                (modsToUpdate, legalModCount) = try await ModChecking.modsToUpdate(
                    info: instance.info)
                if modsToUpdate?.isEmpty == true {
                    try? await Task.sleep(for: .seconds(0.5))
                    isUpToDateOpen = true
                } else {
                    isConfirmationOpen = true
                }
            } catch {
                LogManager.shared.appendLog("Failed to get mods to update", error)
                isFailedModListErrorOpen = true
            }
        }
    }
}
