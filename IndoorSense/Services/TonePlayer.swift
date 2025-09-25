// FILEPATH: IndoorSense/Services/TonePlayer.swift
import AVFoundation

/// Simple audio tone player using short bundled WAV files.
/// Name your files like: room.wav, corridor.wav, elevator.wav, stairs.wav, bathroom.wav, landmark.wav
/// Drop them into the main app target. If a file is missing, play() will no-op gracefully.
final class TonePlayer {
  static let shared = TonePlayer()

  private var players: [FeatureType: AVAudioPlayer] = [:]

  private init() {
    // Preload players (optional). Missing files are simply skipped.
    FeatureType.allCases.forEach { type in
      if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav") {
        do {
          let p = try AVAudioPlayer(contentsOf: url)
          p.prepareToPlay()
          players[type] = p
        } catch {
          print("⚠️ Could not load sound for \(type): \(error)")
        }
      }
    }
  }

  func play(for type: FeatureType) {
    if let p = players[type] {
      // Restart from beginning for quick blips
      p.currentTime = 0
      p.play()
    } else {
      // No sound file present; that's fine for the assignment.
      // You can add actual wavs later if you like.
    }
  }
}
