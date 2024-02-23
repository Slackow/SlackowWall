//
//  PreviewActionsListener.swift
//  SlackowWall
//
//  Created by Kihron on 1/19/23.
//

import SwiftUI
import AVFoundation

struct PreviewActionsListener: NSViewRepresentable {
    var lockAction: ((NSEvent)->())?

    func updateNSView(_ nsView: ActionListener, context: NSViewRepresentableContext<PreviewActionsListener>) {
    }

    func makeNSView(context: Context) -> ActionListener {
        ActionListener(lockAction: lockAction)
    }
}

class ActionListener: NSView {
    var lockAction: (NSEvent) -> ()
    
    init(lockAction: ((NSEvent)->())?) {
        self.lockAction = lockAction ?? {_ in}
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        lockAction(theEvent)
    }
}
