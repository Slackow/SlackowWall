//
//  LockIcon.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

struct LockIcon: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var personalizeManager = PersonalizeManager.shared
    
    private var preset: LockPreset {
        return profileManager.profile.selectedLockPreset
    }
    
    var body: some View {
        VStack {
            if profileManager.profile.lockMode == .preset {
                preset.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity.combined(with: .scale))
                    .foregroundColor(.red)
                    .id(preset)
            } else if let lock = personalizeManager.selectedUserLock?.getIconImage() {
                Image(nsImage: lock)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut, value: profileManager.profile.lockMode)
        .animation(.easeInOut, value: profileManager.profile.selectedUserLock)
        .animation(.easeInOut, value: profileManager.profile.selectedLockPreset)
    }
}

#Preview {
    LockIcon()
        .frame(width: 32, height: 32)
}
