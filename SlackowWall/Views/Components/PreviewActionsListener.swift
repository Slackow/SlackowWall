//
//  PreviewActionsListener.swift
//  SlackowWall
//
//  Created by Dominic Thompson on 1/19/23.
//

import SwiftUI
import AVFoundation

struct PreviewActionsListener: NSViewRepresentable {
    var lockAction: (()->())?

    func updateNSView(_ nsView: ActionListener, context: NSViewRepresentableContext<PreviewActionsListener>) {
    }

    func makeNSView(context: Context) -> ActionListener {
        ActionListener(lockAction: lockAction)
    }
}

class ActionListener: NSView {
    var lockAction: (()->())?
    
    init(lockAction: (()->())?) {
        self.lockAction = lockAction
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        if theEvent.modifierFlags.contains(.shift) {
            if let lockAction = lockAction {
                lockAction()
            }
            playLockSound()
        } else {
            print("left click detected")
        }
    }
    var player: AVAudioPlayer?

    func playLockSound() {
        guard let url = Bundle.main.url(forResource: "lock", withExtension: "wav") else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
