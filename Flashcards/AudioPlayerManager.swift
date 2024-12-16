//
//  AudioPlayerManager.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 13.01.2024.
//

import Foundation
import AVFoundation

class AudioPlayerManager {
    @MainActor static let shared = AudioPlayerManager()
    private var audioPlayer: AVPlayer?
    
    func playSound(from url: String) {
        print("Playing audio from: \(url)")
        guard let url = URL(string: url) else { return }
        
        // Stop the player if it is already playing
        stopSound()
        
        // Initialize the player with the URL
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }
    
    func stopSound() {
        audioPlayer?.pause()
        audioPlayer = nil
    }
}
