//
//  ToolbarUtilityModeView.swift
//  SlackowWall
//
//  Created by Andrew on 4/24/25.
//

import SwiftUI

struct ToolbarUtilityModeView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    
    @State private var isHovered: Bool = false
    @State private var isActuallyHovered: Bool = false
    
    var body: some View {
            Button(action: {profileManager.profile.utilityMode.toggle()}) {
                Image(systemName: "hammer\(profileManager.profile.utilityMode ? ".fill" : "")")
            }
            .popover(isPresented: $isHovered) {
                Text("Utility Mode")
                    .padding()
                    .allowsHitTesting(false)
            }
            .onHover {
                isHovered = $0
                isActuallyHovered = $0
            }
            .onChange(of: isHovered) { hovered in
                if hovered != isActuallyHovered {
                    profileManager.profile.utilityMode.toggle()
                }
            }
    }
}
