//
//  ProfileSettings.swift
//  SlackowWall
//
//  Created by Kihron on 5/17/24.
//

import SwiftUI

struct ProfileSettings: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var selectedProfile = ProfileManager.shared.activeProfile
    
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
                        
                        Picker("", selection: $selectedProfile) {
                            ForEach(profileManager.profileNames, id: \.id) { profile in
                                Text(profile.name)
                                    .tag(profile.id)
                            }
                        }
                        .frame(maxWidth: 120)
                        .labelsHidden()
                    }
                }
                
                SettingsLabel(title: "Properties")
                    .padding(.top, 5)
                
                SettingsCardView {
                    HStack {
                        Text("Name")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("", text: $profileManager.profile.profileName, onCommit: {
                            if profileManager.profile.profileName.isEmpty {
                                DispatchQueue.main.async {
                                    profileManager.profile.profileName = "Default"
                                }
                            }
                        })
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
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
                                    Text("Use Monitor")
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
                    Button(action: profileManager.createNewProfile) {
                        Image(systemName: "plus")
                    }
                    .frame(width: 28)
                    .help("Create new profile")
                    .disabled(profileManager.profiles.count >= 10)
                    
                    
                    Button(action: profileManager.deleteCurrentProfile) {
                        Image(systemName: "trash")
                    }
                    .frame(width: 28)
                    .help("Remove current profile")
                    .disabled(profileManager.profiles.count <= 1)
                
                }
                .frame(width: 56, height: 32, alignment: .trailing)
            }
        }
        .onChange(of: selectedProfile) { value in
            if profileManager.activeProfile != selectedProfile {
                Task {
                    profileManager.activeProfile = value
                    TrackingManager.shared.trackedInstances.forEach({ $0.stream.clearCapture() })
                    await ScreenRecorder.shared.resetAndStartCapture(shouldAutoSwitch: false)
                    GridManager.shared.showInfo = false
                }
            } else if profileManager.profileCreatedOrDeleted {
                Task {
                    await ScreenRecorder.shared.resetAndStartCapture(shouldAutoSwitch: false)
                    GridManager.shared.showInfo = false
                    profileManager.profileCreatedOrDeleted = false
                }
            }
        }
        .onChange(of: profileManager.activeProfile) { value in
            LogManager.shared.appendLog("Switched Profiles:", value)
            profileManager.profile = Profile()
            
            if selectedProfile != value {
                selectedProfile = value
            }
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
