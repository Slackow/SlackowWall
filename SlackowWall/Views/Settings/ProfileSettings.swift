//
//  ProfileSettings.swift
//  SlackowWall
//
//  Created by Kihron on 5/17/24.
//

import SwiftUI

struct ProfileSettings: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsCardView {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Current Profile")
                            
                            Text("Profiles allow for switching between different sets of setting configurations.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Picker("", selection: $profileManager.activeProfile) {
                            ForEach(profileManager.profileNames, id: \.id) { profile in
                                Text(profile.name)
                                    .tag(profile.id)
                            }
                        }
                        .onAppear {
                            print(profileManager.profileNames)
                        }
                        .frame(maxWidth: 100)
                        .labelsHidden()
                    }
                }
                
                SettingsLabel(title: "Properties")
                    .padding(.top, 5)
                
                SettingsCardView {
                    HStack {
                        Text("Name")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("", text: $profileManager.profile.profileName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    }
                }
                
                SettingsCardView {
                    Form {
                        VStack {
                            VStack(spacing: 2) {
                                Text("Automatic Switching")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(.init("Automatically switches to this profile if the current monitor matches these dimensions."))
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(.gray)
                            }
                            
                            HStack(spacing: 24) {
                                HStack {
                                    TextField("W", value: $profileManager.profile.expectedMWidth, format: .number.grouping(.never))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                    
                                    TextField("H", value: $profileManager.profile.expectedMHeight, format: .number.grouping(.never))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                                
                                Button(action: fillMonitorSize) {
                                    Text("Copy Monitor")
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .removeFocusOnTap()
        .toolbar {
            ToolbarItemGroup {
                HStack {
                    Button(action: { profileManager.createNewProfile() }) {
                        Image(systemName: "plus")
                    }
                    .frame(width: 28)
                    .help("Create new profile")
                    
                    if profileManager.profiles.count > 1 {
                        Button(action: { profileManager.deleteCurrentProfile() }) {
                            Image(systemName: "trash")
                        }
                        .frame(width: 28)
                    }
                }
                .frame(width: 56, height: 32, alignment: .trailing)
                .animation(.bouncy(duration: 0.2), value: profileManager.profiles)
            }
        }
        .onChange(of: profileManager.activeProfile) { value in
            profileManager.profile = Profile()
        }
    }
    
    private func fillMonitorSize() {
        if let frame = NSScreen.main?.frame {
            profileManager.profile.expectedMWidth = Int(frame.width)
            profileManager.profile.expectedMHeight = Int(frame.height)
        }
    }
}

#Preview {
    ProfileSettings()
}
