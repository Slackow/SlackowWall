//
//  PersonalizeSettings.swift
//  SlackowWall
//
//  Created by Kihron on 7/23/24.
//

import SwiftUI

struct PersonalizeSettings: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var personalizeManager = PersonalizeManager.shared
    
    @State private var debounceWorkItem: DispatchWorkItem?
    @State private var showLockEditor: Bool = false
    
    var body: some View {
        SettingsPageView(title: "Personalize") {
            SettingsLabel(title: "Video")
            
            SettingsCardView {
                SettingsSliderView(title: "Stream FPS (\(Int(profileManager.profile.streamFPS)))", leftIcon: "figure.walk", rightIcon: "figure.walk.motion", value: $profileManager.profile.streamFPS, range: 15...60, step: 5)
            }
            
            SettingsLabel(title: "Appearance", description: "Adjust different visual effects and components throughout the app.")
                .padding(.top, 5)
            
            SettingsCardView {
                VStack {
                    SettingsButtonView(title: "Lock Icon", description: "Customize the lock image used throughout SlackowWall.", action: { showLockEditor.toggle() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray)
                            
                            LockIcon()
                                .frame(width: 32, height: 32)
                        }
                        .frame(width: 42, height: 42)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.bottom, 4)
                    
                    SettingsSliderView(title: "Lock Scale", leftIcon: "dial.low.fill", rightIcon: "dial.high.fill", value: $profileManager.profile.lockScale, range: 0.5...1.5, step: 0.25)
                    
                    Divider()
                        .padding(.bottom, 4)
                    
                    SettingsToggleView(title: "Lock Animation", option: $profileManager.profile.lockAnimation)
                }
            }
        }
        .sheet(isPresented: $showLockEditor) {
            LockIconEditor()
        }
        .onChange(of: profileManager.profile.streamFPS) { _ in
            debounceResetAndStartCapture()
        }
    }
    
    private func debounceResetAndStartCapture() {
        debounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            Task {
                await ScreenRecorder.shared.resetAndStartCapture()
                GridManager.shared.showInfo = false
            }
        }
        
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
}

#Preview {
    PersonalizeSettings()
}
