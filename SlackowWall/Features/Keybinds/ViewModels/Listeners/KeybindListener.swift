//
// Created by Kihron on 1/19/23.
//

import SwiftUI

struct KeybindListener: NSViewRepresentable {
    @Binding var key: KeyAction?

    class KeyView: NSView {
        @Binding var key: KeyAction?

        init(key: Binding<KeyAction?>) {
            self._key = key
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            guard let action = KeyAction.from(keyCode: event.keyCode) else { return }
            key = action
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = KeyView(key: $key)
        DispatchQueue.main.async {  // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
