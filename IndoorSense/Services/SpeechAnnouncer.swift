// FILEPATH: IndoorSense/Services/SpeechAnnouncer.swift
import AVFoundation
import UIKit

final class SpeechAnnouncer {
  static let shared = SpeechAnnouncer()

  private let synth = AVSpeechSynthesizer()
  /// If true, we speak even when VoiceOver is running (handy for demos).
  var alwaysSpeak = false

  private init() {
    do {
      // Mix with other audio so system sounds/VO aren’t cut off.
      try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("⚠️ AVAudioSession error:", error)
    }
  }

  func say(_ text: String,
           language: String = "en-US",
           rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
    if UIAccessibility.isVoiceOverRunning && !alwaysSpeak { return }
    guard !text.isEmpty else { return }

    let utter = AVSpeechUtterance(string: text)
    utter.voice = AVSpeechSynthesisVoice(language: language)
    utter.rate = rate
    synth.stopSpeaking(at: .immediate) // snappy while tracing
    synth.speak(utter)
  }
}
