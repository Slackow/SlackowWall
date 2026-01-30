//
//  KeybindingView.swift
//  SlackowWall
//
//  Created by Andrew on 2/23/24.
//

// FocusableBridge.swift
import AppKit
import SwiftUI

struct KeybindingView: View {
    @Binding var keybinding: Keybinding
    @FocusState var isActuallyFocused: Bool
    @State var isFocused: Bool = false
    @State private var circleColor: Color = .gray
    var defaultValue: Keybinding = .none
    @State private var monitor: Any?

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
        }
        .frame(width: 135, height: 22)
        .focusable(true)
        .focused($isActuallyFocused)
        .overlay {
            Button(action: {
                if #available(macOS 14.0, *) {
                    keybinding = defaultValue
                    isFocused = false
                    isActuallyFocused = false
                } else {
                    if isFocused {
                        keybinding = defaultValue
                        isFocused = false
                    } else {
                        isFocused = true
                    }

                }
            }) {
                ZStack {
                    if #available(macOS 14.0, *) {
                        Circle()
                            .fill(defaultValue == keybinding ? .gray.opacity(0.5) : circleColor)
                            .frame(width: 16)
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.init(nsColor: .windowBackgroundColor))
                    } else {
                        Circle()
                            .fill(circleColor)
                            .frame(width: 16)
                        Image(systemName: isFocused ? "xmark" : "pencil")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.init(nsColor: .windowBackgroundColor))
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .onHover(perform: { hovering in
                circleColor = hovering ? .init(nsColor: .labelColor) : .gray
            })
            .frame(maxWidth: .infinity, alignment: .trailing)
            .keyboardShortcut(nil)
        }
        .onAppear {
            // Setup local key event monitoring
            monitor = NSEvent.addLocalMonitorForEvents(
                matching: [.keyDown, .keyUp, .flagsChanged]
            ) { event in
                if !isFocused { return event }

                var type = event.type
                if type == .flagsChanged,
                    let code = KeyCode.modifierFlags(code: event.keyCode)
                {
                    type = event.modifierFlags.contains(code) ? .keyDown : .keyUp

                }

                if type == .keyDown {
                    return nil
                } else if type == .keyUp {
                    if event.keyCode == .escape {
                        keybinding = .none
                    } else {
                        keybinding = Keybinding(event: event)
                    }
                    isFocused = false
                    isActuallyFocused = false
                    return nil
                }

                return event
            }
        }
        .onDisappear {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
        .onChange(of: isActuallyFocused) { newValue in
            isFocused = isActuallyFocused
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
