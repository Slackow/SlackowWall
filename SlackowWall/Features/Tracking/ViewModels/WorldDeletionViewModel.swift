import SwiftUI

@MainActor
final class WorldDeletionViewModel: ObservableObject {
    @Published var isDeleting = false
    @Published var deletionProgress: Double = 0
    @Published var showDeleteConfirm = false
    @Published var showNoWorldsAlert = false

    private var worldsToDelete: [URL] = []

    var deletionCount: Int { worldsToDelete.count }

    /// Prepare deletion by enumerating removable worlds in the given instance path.
    func prepareDeletion(instancePath: String) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let worlds = try WorldClearing.worldsToDelete(at: instancePath + "/saves/")
                DispatchQueue.main.async {
                    if worlds.isEmpty {
                        self.showNoWorldsAlert = true
                    } else {
                        self.worldsToDelete = worlds
                        self.showDeleteConfirm = true
                    }
                }
            } catch {
                LogManager.shared.appendLog("Failed to enumerate worlds: \(error)")
            }
        }
    }

    /// Start asynchronous deletion showing progress updates.
    func startDeletion() {
        let worlds = worldsToDelete
        isDeleting = true
        deletionProgress = 0

        Task.detached(priority: .utility) {
            WorldClearing.deleteWorlds(worlds) { cleared, total in
                Task { @MainActor in
                    self.deletionProgress = Double(cleared) / Double(total)
                }
            }
            Task { @MainActor in
                self.isDeleting = false
                self.worldsToDelete.removeAll()
            }
        }
    }

    /// Cancel deletion dialog.
    func cancelDeletion() {
        worldsToDelete.removeAll()
    }
}
