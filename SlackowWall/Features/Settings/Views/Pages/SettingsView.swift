//
//  SettingsView.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var alertManager = AlertManager.shared
    @State var selectedSettingsBarItem: SettingsBarItem = .utilities

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSettingsBarItem) {
                Section("General") {
                    ForEach(SettingsBarItem.generalCases) { item in
                        createSidebarItem(item: item)
                    }
                }
                Section("Wall") {
                    ForEach(SettingsBarItem.wallCases) { item in
                        createSidebarItem(item: item)
                    }
                }
            }
            .removeSidebar()
            .navigationSplitViewColumnWidth(200)
        } detail: {
            Group {
                switch selectedSettingsBarItem {
                    case .instances:
                        InstancesSettings()
                    case .behavior:
                        BehaviorSettings()
                    case .window_resizing:
                        ModeSettings()
                    case .utilities:
                        UtilitySettings()
                    case .keybindings:
                        KeybindingsSettings()
                    case .wall_keybindings:
                        WallKeybindingsSettings()
                    case .personalize:
                        PersonalizeSettings()
                    case .profiles:
                        ProfilesSettings()
                    case .updates:
                        UpdateSettings()
                    case .credits:
                        CreditsView()
                }
            }
            .navigationSplitViewColumnWidth(500)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if alertManager.alert != nil {
                    ToolbarAlertView()
                }
            }
        }
    }

    @ViewBuilder func createSidebarItem(item: SettingsBarItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(item.color.gradient)
                    .frame(width: 25, height: 25)

                Image(item.icon)
                    .resizable()
                    .scaledToFit()
                    .padding(1)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, alignment: .center)
            }

            Text(item.label)
                .tint(.primary)
            if case .some((let icon, let color)) = item.secondIcon {
                Image(icon)
                    .foregroundColor(color)

            }
        }
        .frame(height: 20)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .tag(item)
    }
}

#Preview {
    SettingsView()
        .frame(maxWidth: .infinity)
}
