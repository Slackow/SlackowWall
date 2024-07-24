//
//  LockIconEditor.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

struct LockIconEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var personalizeManager = PersonalizeManager.shared
    
    @State private var editMode: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Lock Icons")
                .font(.title2)
                .fontWeight(.bold)
            
            SettingsCardView(padding: 0) {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 42), spacing: 0), count: 7)) {
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
                        
                        ForEach(LockPreset.allCases) { preset in
                            Button(action: { personalizeManager.selectLockPreset(preset: preset) }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(profileManager.profile.lockMode == .preset && profileManager.profile.selectedLockPreset == preset ? .white : .gray, lineWidth: 1)
                                    
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
                        }
                        
                        ForEach(personalizeManager.lockIcons) { lock in
                            Button(action: { personalizeManager.selectUserLockIcon(userLock: lock) }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(lock == profileManager.profile.selectedUserLock ? .white : .gray, lineWidth: 1)
                                    
                                    Image(nsImage: lock.getIconImage() ?? NSImage())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                        .foregroundStyle(.red)
                                }
                                .frame(width: 42, height: 42)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .disabled(editMode)
                            .overlay {
                                if editMode {
                                    Button(action: { personalizeManager.deleteLockIcon(userLock: lock) }) {
                                        ZStack {
                                            Circle()
                                                .fill(.red)
                                            
                                            Image(systemName: "xmark")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                        }
                                        .frame(width: 16, height: 16)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .offset(x: 6, y: -5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
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
        .animation(.easeInOut, value: profileManager.profile.selectedUserLock)
        .animation(.easeInOut, value: profileManager.profile.selectedLockPreset)
        .animation(.easeInOut, value: personalizeManager.lockIcons)
    }
}

#Preview {
    LockIconEditor()
}
