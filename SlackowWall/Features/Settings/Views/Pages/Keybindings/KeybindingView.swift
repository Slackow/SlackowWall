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
        .overlay {
            if isFocused {
                FocusableBridge()
                    .allowsHitTesting(false)
                    .frame(width: 0, height: 0)
            }
        }
        .focusable(true)
        .focused($isFocused)
        .overlay {
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
                    return nil
                }

                return event
            }
        }
        .onDisappear {
            if let monitor { NSEvent.removeMonitor(monitor) }
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

// FocusableBridge.swift
import AppKit
import SwiftUI

final class FocusableBridgeNSView: NSView {
    // We’ll ask to become first responder so key events route predictably.
    override var acceptsFirstResponder: Bool { true }
    var onBecameFirstResponder: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // If already requested, try to become first responder now.
        DispatchQueue.main.async { [weak self] in
            guard let self, let wnd = self.window else { return }
            wnd.makeFirstResponder(self)
            self.onBecameFirstResponder?()
        }
    }
}

struct FocusableBridge: NSViewRepresentable {
    var onReady: ((NSView) -> Void)? = nil

    func makeNSView(context: Context) -> FocusableBridgeNSView {
        let v = FocusableBridgeNSView()
        v.onBecameFirstResponder = {
            // no-op; we just ensure first responder is acquired
        }
        return v
    }

    func updateNSView(_ nsView: FocusableBridgeNSView, context: Context) {
        // no-op
    }
}
