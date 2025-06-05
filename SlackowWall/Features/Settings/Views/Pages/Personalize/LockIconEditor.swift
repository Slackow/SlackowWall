//
//  LockIconEditor.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

struct LockIconEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var personalizeManager = PersonalizeManager.shared

    @AppSettings(\.personalize) private var settings

    @State private var editMode: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Lock Icons")
                .font(.title2)
                .fontWeight(.bold)

            SettingsCardView(padding: 0) {
                ScrollView {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.adaptive(minimum: 42), spacing: 0), count: 7)
                    ) {
                        Button(action: { personalizeManager.selectImage() }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.gray, lineWidth: 1)

                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.gray.opacity(0.1))

                                Image(systemName: "plus")
                                    .font(.title)
                            }
                            .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                        .disabled(editMode)

                        ForEach(LockPreset.allCases) { preset in
                            Button(action: { personalizeManager.selectLockPreset(preset: preset) })
                            {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(
                                            settings.lockMode == .preset
                                                && settings.selectedLockPreset == preset
                                                ? .white : .gray, lineWidth: 1)

                                    preset.image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                        .foregroundStyle(.red)
                                }
                                .frame(width: 42, height: 42)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 10)
                            .disabled(editMode)
                        }

                        ForEach(personalizeManager.lockIcons) { lock in
                            ZStack {
                                Button(action: {
                                    personalizeManager.selectUserLockIcon(userLock: lock)
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(
                                                lock == settings.selectedUserLock ? .white : .gray,
                                                lineWidth: 1)

                                        Image(nsImage: lock.getIconImage() ?? NSImage())
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 32, height: 32)
                                            .foregroundStyle(.red)
                                    }
                                    .frame(width: 42, height: 42)
                                    .contentShape(.rect)
                                }
                                .disabled(editMode)

                                if editMode {
                                    Button(action: {
                                        personalizeManager.deleteLockIcon(userLock: lock)
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(.red)
                                                .frame(width: 16, height: 16)

                                            Image(systemName: "xmark")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                        }
                                        .frame(width: 16, height: 16)
                                        .contentShape(.rect)
                                        .frame(
                                            maxWidth: .infinity, maxHeight: .infinity,
                                            alignment: .topTrailing
                                        )
                                        .padding(.trailing, 4)
                                        .padding(.top, -6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 10)
                        }
                    }
                    .animation(.easeInOut, value: editMode)
                    .padding(10)
                }
            }

            HStack {
                Button(action: { editMode.toggle() }) {
                    Text(editMode ? "Done" : "Edit")
                }

                Button(action: { dismiss() }) {
                    Text("Close")
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 500, height: 300)
        .animation(.easeInOut, value: settings.selectedUserLock)
        .animation(.easeInOut, value: settings.selectedLockPreset)
        .animation(.easeInOut, value: personalizeManager.lockIcons)
    }
}

#Preview {
    LockIconEditor()
}
