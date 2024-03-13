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
    
    @State
    var circleColor: Color = .gray
    
    var body: some View {
        ZStack {
            Rectangle()
                .roundedCorners(radius: 5, corners: .allCorners)
                .foregroundColor(.init(red: 0.25, green: 0.25, blue: 0.25))
            
            HStack {
                Spacer()
                Text(isFocused ? "> \(textName) <" : textName)
                    .foregroundStyle(isFocused ? .gray : .white)
                Spacer()
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 15)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }.padding(2)
                    .overlay(PreviewActionsListener(lockAction: {_ in
                        keybinding = nil
                    }))
                    .onHover(perform: { hovering in
                        circleColor = hovering ? .white : .gray
                    })
            }
        }.frame(width: 100, height: 22)
            .focusable(true)
            .focused($isFocused)
            .onAppear {
            // Setup local key event monitoring
            _ = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if !isFocused { return event }
                keybinding = event.keyCode
                print("Set Key to:")
                return nil // Return the event for further processing
            }
        }
    }
}
#Preview {
    VStack {
        KeybindingView(keybinding: KeybindingManager.shared.$resetGKey)
            .padding()
        KeybindingView(keybinding: KeybindingManager.shared.$resetAllKey)
            .padding()
    }
}
