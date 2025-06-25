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

    var body: some View {
        VStack(alignment: .leading) {
            Text("Mods - \(viewModel.mods.count)")
                .font(.title2)
                .fontWeight(.bold)

            SettingsCardView(padding: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.mods) { (mod: ModInfo) in
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
    }
}
