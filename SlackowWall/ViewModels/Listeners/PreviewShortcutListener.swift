//
// Created by Kihron on 1/19/23.
//

import SwiftUI

struct PreviewShortcutListener: NSViewRepresentable {
    @Binding var key: Character?

    class KeyView: NSView {
        @Binding var key: Character?

        init(key: Binding<Character?>) {
            self._key = key
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            let k = KeybindingManager.shared
            switch event.keyCode {
            case k.runKey: key = "r"
            case k.resetOneKey: key = "e"
            case k.resetOthersKey: key = "f"
            case k.resetAllKey: key = "t"
            case k.lockKey: key = "c"
            case k.resetGKey: key = "u"
            default: return
            }
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = KeyView(key: $key)
        DispatchQueue.main.async { // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
    
    
}
