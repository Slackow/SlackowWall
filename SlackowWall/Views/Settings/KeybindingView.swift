//
//  KeybindingView.swift
//  SlackowWall
//
//  Created by Andrew on 2/23/24.
//

import SwiftUI

struct KeybindingView: View {
    @Binding var keybinding: UInt16?
    @FocusState var isFocused: Bool
    
    var textName: String {
        KeyCode.toName(code: keybinding)
    }
    
    var body: some View {
            ZStack {
                Rectangle()
                    .roundedCorners(radius: 5, corners: .allCorners)
                    .foregroundColor(.init(red: 0.25, green: 0.25, blue: 0.25))
                    
                HStack {
                    Spacer()
                    Text(textName)
                        .foregroundStyle(isFocused ? .gray : .white)
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 15)
                            
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }.padding(2)
                        .overlay(PreviewActionsListener(lockAction: {_ in
                            keybinding = .apostrophe
                            print("ow \(keybinding ?? 0) \(KeyCode.toName(code: keybinding))")
                        }))
                }
            }.frame(width: 100, height: 22)
            .focusable(true)
            .focused($isFocused)
            
    }
}

#Preview {
    VStack {
        KeybindingView(keybinding: KeybindingManager.shared.$resetGKey)
            .padding()
        KeybindingView(keybinding: KeybindingManager.shared.$resetGKey)
            .padding()
    }
}
