//
//  PrismQuickLaunchView.swift
//  SlackowWall
//
//  Created by Andrew on 5/30/25.
//

import SwiftUI

struct PrismQuickLaunchView: View {
    @StateObject private var store = PrismInstanceStore()
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private let grid = [GridItem(.adaptive(minimum: 140), spacing: 16)]

    // Filtered list based on search string
    private var filteredInstances: [PrismInstance] {
        if searchText.isEmpty {
            return store.instances
        }
        return store.instances.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    /// Launches the instance and closes the sheet.
    private func launchAndDismiss(_ instance: PrismInstance) {
        store.launch(instance)
        dismiss()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !store.favourites.isEmpty {
                    Text("Pinned")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: grid, spacing: 16) {
                        ForEach(store.favourites) { inst in
                            PrismInstanceCell(
                                instance: inst,
                                isFavourite: true,
                                toggleFavourite: store.toggleFavourite,
                                launch: launchAndDismiss)
                        }
                    }
                    .padding(.horizontal)
                }

                Text("All Instances")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: grid, spacing: 16) {
                    ForEach(filteredInstances) { inst in
                        PrismInstanceCell(
                            instance: inst,
                            isFavourite: store.isFavourite(inst),
                            toggleFavourite: store.toggleFavourite,
                            launch: launchAndDismiss)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }.focusable()
            }
        }
        .frame(minWidth: 550, idealWidth: 550, minHeight: 250, idealHeight: 450)
    }
}
