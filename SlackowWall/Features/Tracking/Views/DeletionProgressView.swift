//
//  DeletionProgressView.swift
//  SlackowWall
//
//  Created by Codex.
//

import SwiftUI

struct DeletionProgressView: View {
    @ObservedObject var model: WorldDeletionViewModel

    var body: some View {
        ZStack {
            if model.isDeleting {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView(value: model.deletionProgress)
                        .frame(width: 180)
                    Text("Deleting Worlds… \(Int(model.deletionProgress * 100))%")
                        .font(.caption)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(10)
            }
        }
        .confirmationDialog(
            "Delete \(model.deletionCount) world\(model.deletionCount == 1 ? "" : "s")?",
            isPresented: $model.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { model.startDeletion() }
            Button("Cancel", role: .cancel) { model.cancelDeletion() }
        } message: {
            Text("The 40 most recent worlds will be kept.\nMaps and files should be unaffected.")
        }
        .alert(
            "No deletable worlds found",
            isPresented: $model.showNoWorldsAlert,
            actions: { Button("OK", role: .cancel) {} }
        )
    }
}

#Preview {
    DeletionProgressView(model: WorldDeletionViewModel())
}
