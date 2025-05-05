//
//  LockIcon.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

struct LockIcon: View {
    @AppSettings(\.personalize) private var settings
    @ObservedObject private var personalizeManager = PersonalizeManager.shared
    
    private var preset: LockPreset {
        return settings.selectedLockPreset
    }
    
    var body: some View {
        VStack {
            if settings.lockMode == .preset {
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
        .animation(.easeInOut, value: settings.lockMode)
        .animation(.easeInOut, value: settings.selectedUserLock)
        .animation(.easeInOut, value: settings.selectedLockPreset)
    }
}

#Preview {
    LockIcon()
        .frame(width: 32, height: 32)
}
