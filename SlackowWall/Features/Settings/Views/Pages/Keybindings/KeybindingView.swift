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
    
    init(keybinding: Binding<UInt16?>, defaultValue: UInt16? = nil) {
        _keybinding = keybinding
        self.defaultValue = defaultValue
    }
    
    @AppSettings(\.keybinds) private var settings
    init(keybinding keyPath: WritableKeyPath<Preferences.KeybindSection, UInt16?>) {
        let binding = Binding<UInt16?>(
            get: { Settings[\.keybinds][keyPath: keyPath] },
            set: { Settings[\.keybinds][keyPath: keyPath] = $0 }
        )
        _keybinding = binding
        defaultValue = Preferences.KeybindSection()[keyPath: keyPath]
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
                isFocused = false
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
    @AppSettings(\.keybinds)
    var settings
    VStack {
        KeybindingView(keybinding: $settings.resetGKey, defaultValue: nil)
            .padding()
        KeybindingView(keybinding: $settings.resetAllKey, defaultValue: .t)
            .padding()
    }
}
