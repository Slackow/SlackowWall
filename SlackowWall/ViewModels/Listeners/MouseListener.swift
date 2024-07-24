//
//  MouseListener.swift
//  SlackowWall
//
//  Created by Kihron on 1/19/23.
//

import SwiftUI
import AVFoundation

struct MouseListener: NSViewRepresentable {
    var action: ((NSEvent)->())?

    func updateNSView(_ nsView: ActionListener, context: NSViewRepresentableContext<MouseListener>) {
    }

    func makeNSView(context: Context) -> ActionListener {
        ActionListener(action: action)
    }
}

class ActionListener: NSView {
    var action: (NSEvent) -> ()
    
    init(action: ((NSEvent)->())?) {
        self.action = action ?? {_ in}
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        action(theEvent)
    }
}
