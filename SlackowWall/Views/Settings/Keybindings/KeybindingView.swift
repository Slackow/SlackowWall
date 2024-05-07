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
    @State private var circleColor: Color = .gray
    var defaultValue: UInt16?
    
    private var textName: String {
        KeyCode.toName(code: keybinding)
    }
    
    
    var body: some View {
        ZStack(alignment: .trailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(.init(red: 0.25, green: 0.25, blue: 0.25))
                
                Text(isFocused ? "> \(textName) <" : textName)
                    .foregroundStyle(isFocused ? .gray : .white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .focusable(true)
            .focused($isFocused)
            
            Button(action: {
                keybinding = defaultValue
            }) {
                ZStack {
                    Circle()
                        .fill(defaultValue == keybinding ? .gray.opacity(0.5) : circleColor)
                        .frame(width: 16)
                    
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .onHover(perform: { hovering in
                circleColor = hovering ? .white : .gray
            })
        }
        .frame(width: 100, height: 22)
        .onAppear {
            // Setup local key event monitoring
            _ = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if !isFocused { return event }
                keybinding = event.keyCode == .escape ? nil : event.keyCode
                isFocused = false
                return nil
            }
        }
    }
}

#Preview {
    VStack {
        KeybindingView(keybinding: KeybindingManager.shared.$resetGKey, defaultValue: .u)
            .padding()
        KeybindingView(keybinding: KeybindingManager.shared.$resetAllKey, defaultValue: .t)
            .padding()
    }
}
