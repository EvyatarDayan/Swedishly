//
//  SpeechManager.swift
//  SWWorder
//
//  Created by assistant on 2026-02-07.
//

import Foundation
import AVFoundation
import Combine
import AudioToolbox

class SpeechManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = SpeechManager()

    @Published var isSpeaking: Bool = false
    var onSpeechFinished: (() -> Void)?

    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    private var currentText: String = ""

    private override init() {
        super.init()
    }

    func speak(_ text: String, language: String = "sv-SE", onFinished: (() -> Void)? = nil) {
        // Stop any current speech
        if isSpeaking {
            stop()
        }

        onSpeechFinished = onFinished
        currentText = text

        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
            onSpeechFinished?()
            return
        }

        // Use Google Translate TTS API (same as TalkSvenska)
        playWebTTS(text: text, language: language)
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
        onSpeechFinished = nil

        // Clean up audio file
        if let audioURL = audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        audioURL = nil
    }

    private func playWebTTS(text: String, language: String) {
        // Map language code to Google TTS language code
        let googleLangCode: String
        switch language {
        case "sv-SE":
            googleLangCode = "sv"
        case "en-US":
            googleLangCode = "en"
        default:
            googleLangCode = "sv" // Default to Swedish
        }

        // Use Google Translate TTS API (same as TalkSvenska)
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedText)&tl=\(googleLangCode)&client=tw-ob"

        guard let url = URL(string: urlString) else {
            print("Failed to create TTS URL")
            playFallbackSound()
            return
        }

        print("Fetching TTS from Google Translate for: \(text)")

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    print("TTS network error: \(error)")
                    self.playFallbackSound()
                    return
                }

                guard let data = data, !data.isEmpty else {
                    print("No TTS data received")
                    self.playFallbackSound()
                    return
                }

                // Save the audio data to a temporary file
                let filename = "tts_\(UUID().uuidString).mp3"
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioURL = documentsPath.appendingPathComponent(filename)

                do {
                    try data.write(to: audioURL)
                    print("TTS audio saved successfully")

                    // Create audio player
                    self.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()

                    self.audioURL = audioURL
                    self.isSpeaking = true

                } catch {
                    print("Error playing TTS: \(error)")
                    self.playFallbackSound()
                }
            }
        }

        task.resume()
    }

    private func playFallbackSound() {
        print("Playing fallback system sound")
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSpeaking = false
            self.onSpeechFinished?()
        }
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.onSpeechFinished?()
            self.onSpeechFinished = nil

            // Clean up audio file
            if let audioURL = self.audioURL {
                try? FileManager.default.removeItem(at: audioURL)
            }
            self.audioURL = nil
            self.audioPlayer = nil
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            print("Audio player decode error: \(error?.localizedDescription ?? "unknown")")
            self.isSpeaking = false
            self.onSpeechFinished?()
            self.onSpeechFinished = nil
        }
    }
}

