//
//  KeybindingView.swift
//  SlackowWall
//
//  Created by Andrew on 2/23/24.
//

import AppKit
import SwiftUI

struct KeybindingView: View {
    @Binding var keybinding: Keybinding
    @FocusState var isFocused: Bool
    @State private var circleColor: Color = .gray
    var defaultValue: Keybinding = .none

    private var textName: String {
        keybinding.displayName
    }

    init(keybinding: Binding<Keybinding>, defaultValue: Keybinding = .none) {
        _keybinding = keybinding
        self.defaultValue = defaultValue
    }

    @AppSettings(\.keybinds) private var settings
    init(keybinding keyPath: WritableKeyPath<Preferences.KeybindSection, Keybinding>) {
        let binding = Binding<Keybinding>(
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
                    .foregroundColor(.init(nsColor: .controlBackgroundColor))

                Text(isFocused ? "> \(textName) <" : textName)
                    .foregroundStyle(isFocused ? .gray : Color(nsColor: .controlTextColor))
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
                        .foregroundColor(.init(nsColor: .windowBackgroundColor))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .onHover(perform: { hovering in
                circleColor = hovering ? .init(nsColor: .labelColor) : .gray
            })
        }
        .frame(width: 150, height: 22)
        .onAppear {
            // Setup local key event monitoring
            _ = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if !isFocused { return event }
                if event.keyCode == .escape {
                    keybinding = defaultValue
                } else {
                    keybinding = Keybinding(event: event)
                }
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
        KeybindingView(keybinding: $settings.planarGKey)
            .padding()
        KeybindingView(keybinding: $settings.resetAllKey, defaultValue: .init(.t))
            .padding()
    }
}
