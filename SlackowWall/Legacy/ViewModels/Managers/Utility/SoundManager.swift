//
//  SoundManager.swift
//  SlackowWall
//
//  Created by Kihron on 1/18/23.
//

import SwiftUI
import AVKit

class SoundManager {
    static let shared = SoundManager()

    var player: AVAudioPlayer?

    func playSound(sound: String, ext: String? = ".wav") {
        guard let url = Bundle.main.url(forResource: sound, withExtension: ext) else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
