//
//  SettingsView.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var alertManager = AlertManager.shared
    @State var selectedSettingsBarItem: SettingsBarItem = .instances
    
    var body: some View {
        NavigationSplitView {
            List(SettingsBarItem.allCases, selection: $selectedSettingsBarItem) { item in
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(item.color.gradient)
                            .frame(width: 25, height: 25)
                        
                        Image(systemName: item.icon)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, alignment: .center)
                            .font(item == .keybindings ? .caption : .body)
                    }
                    
                    Text(item.label)
                        .tint(.primary)
                }
                .frame(height: 20)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .removeSidebar()
            .navigationSplitViewColumnWidth(200)
        }
        detail: {
            Group {
                switch selectedSettingsBarItem {
                    case .instances:
                        InstancesSettings()
                    case .behavior:
                        BehaviorSettings()
                    case .window_resizing:
                        DimensionSettings()
                    case .keybindings:
                        KeybindingsSettings()
                    case .personalize:
                        PersonalizeSettings()
                    case .profiles:
                        ProfileSettings()
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
}

#Preview {
    SettingsView()
        .frame(maxWidth: .infinity)
}
