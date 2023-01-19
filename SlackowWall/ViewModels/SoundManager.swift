//
//  SoundManager.swift
//  SlackowWall
//
//  Created by Dominic Thompson on 1/18/23.
//

import SwiftUI
import AVKit

class SoundManager {
    static let shared = SoundManager()

    var player: AVAudioPlayer?

    func playSound(sound: String) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: ".mp3") else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
