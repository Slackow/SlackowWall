//
//  GameSettingsView.swift
//  SlackowWall
//
//  Created by Andrew on 3/1/24.
//

import SwiftUI

struct GameSettings: View {
    
    @ObservedObject var gameSettingsManager = GameSettingsManager.shared
    
    var body: some View {
        VStack {
            HStack {
                Text("Standard Settings")
                Button(action: {
                }) {
                    Text("+")
                }
            }
        }
    }
}

#Preview {
    GameSettings().padding()
}
