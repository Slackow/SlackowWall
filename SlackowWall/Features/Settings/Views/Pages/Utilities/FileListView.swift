//
//  FileListView.swift
//  SlackowWall
//
//  Created by Andrew on 9/7/25.
//

import SwiftUI
import AppKit

/// macOS-only URL manager using NSOpenPanel for adding files/folders.
struct FileListView: View {
    @Binding var urls: [URL]

    @State private var selection = Set<URL>()   // multi-select of items in the list

    var body: some View {
        VStack(spacing: 12) {
            List(urls, id: \.self, selection: $selection) { url in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(url.lastPathComponent)
                            .font(.body)
                            .lineLimit(1)
                        Text(url.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    // Quick reveal button
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .help("Reveal in Finder")
                    }
                    .buttonStyle(.borderless)
                }
                .contextMenu {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Label("Reveal in Finder", systemImage: "magnifyingglass")
                    }
                    Divider()
                    Button(role: .destructive) {
                        remove(url)
                    } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                }
                .help(url.path)
            }
            .frame(minHeight: 80)

            HStack(spacing: 10) {
                Button {
                    presentOpenPanel()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .keyboardShortcut(.init("n"), modifiers: [.command]) // ⌘N to add

                Button(role: .destructive) {
                    removeSelected()
                } label: {
                    Label("Remove", systemImage: "minus")
                }
                .disabled(selection.isEmpty)
                .keyboardShortcut(.delete, modifiers: []) // ⌫ to remove

                Spacer()
                Text("\(urls.count) item\(urls.count == 1 ? "" : "s")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true     // toggle off if you only want files
        panel.canCreateDirectories = false
        panel.resolvesAliases = true
        panel.treatsFilePackagesAsDirectories = false
        panel.prompt = "Add"
        panel.message = "Select files or folders to add."

        if panel.runModal() == .OK {
            appendUnique(panel.urls)
        }
    }

    private func appendUnique(_ new: [URL]) {
        let existing = Set(urls)
        let filtered = new.filter { !existing.contains($0) }
        guard !filtered.isEmpty else { return }
        urls.append(contentsOf: filtered)
    }

    private func removeSelected() {
        urls.removeAll { selection.contains($0) }
        selection.removeAll()
    }

    private func remove(_ url: URL) {
        urls.removeAll { $0 == url }
        selection.remove(url)
    }

    private func fileIcon(for url: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}
