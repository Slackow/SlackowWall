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
            let p = ProfileManager.shared.profile
            switch event.keyCode {
            case p.runKey: key = "r"
            case p.resetOneKey: key = "e"
            case p.resetOthersKey: key = "f"
            case p.resetAllKey: key = "t"
            case p.lockKey: key = "c"
            case p.resetGKey: key = "u"
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
