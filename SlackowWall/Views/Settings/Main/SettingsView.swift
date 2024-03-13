//
//  SettingsView.swift
//  SlackowWall
//
//  Created by Kihron on 1/8/23.
//

import SwiftUI

struct SettingsView: View {
    @State var sideBarVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State var selectedSettingsBarItem: SettingsBarItem = .instances
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sideBarVisibility) {
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
                    }
                    
                    Text(item.label)
                        .tint(.primary)
                }
                .frame(height: 20)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .frame(width: 205)
            .removeSidebar()
        }
    detail: {
        switch selectedSettingsBarItem {
            case .keybindings:
                KeybindingSettings()
            case .instances:
                InstancesSettings()
            case .updates:
                UpdateSettings()
            }
        }
    }
}

#Preview {
    SettingsView()
        .frame(maxWidth: .infinity)
}
