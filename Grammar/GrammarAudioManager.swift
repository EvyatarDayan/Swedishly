//
//  GrammarAudioManager.swift
//  SWGrammar (renamed from AudioManager.swift to avoid duplicate build output)
//
//  Created by EVYATAR DAYAN on 2026-01-20.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import AudioToolbox

class GrammarAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var isAudioReady = false
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    private var currentText: String = ""
    private var sentenceParts: (before: String, after: String)?
    private var audioQueue: [URL] = []
    private var currentQueueIndex = 0

    func generateAudio(for text: String, withBeepAt answer: String? = nil) {
        // Reset state
        isAudioReady = false
        isPlaying = false
        currentText = text

        // If answer is provided, split the sentence and prepare for beep insertion
        if let answer = answer, text.contains(answer) {
            // Find the first occurrence of the answer word (as a whole word, not substring)
            // This handles cases where the answer might appear multiple times
            if let range = text.range(of: answer) {
                let before = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let after = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                sentenceParts = (before: before, after: after)
                print("Generating audio with beep for: '\(before)' [BEEP] '\(after)'")
            } else {
                sentenceParts = nil
                print("Generating audio for: \(text)")
            }
        } else {
            sentenceParts = nil
            print("Generating audio for: \(text)")
        }

        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
            self.isAudioReady = false
            return
        }

        // Use direct speech synthesis
        self.isAudioReady = true
        print("TTS ready for direct playback")
    }

    func playAudio() {
        guard !isPlaying, isAudioReady else {
            print("Cannot play audio - isPlaying: \(isPlaying), isReady: \(isAudioReady)")
            return
        }

        print("Playing TTS audio (Google TTS, same as Vocabulary)...")
        isPlaying = true
        // Use same text-to-sound system as Vocabulary: Google Translate TTS + 440Hz beep for gap
        if let parts = sentenceParts {
            let before = parts.before.trimmingCharacters(in: .whitespaces)
            let after = parts.after.trimmingCharacters(in: .whitespaces)
            generateAudioWithBeep(before: before, after: after)
        } else {
            fetchAndPlayFullSentence()
        }
    }

    func cleanupAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isAudioReady = false

        for url in audioQueue {
            try? FileManager.default.removeItem(at: url)
        }
        audioQueue = []
        currentQueueIndex = 0

        if let audioURL = audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        audioURL = nil
    }

    private func removeQuestionMarks(from text: String) -> String {
        return text.replacingOccurrences(of: "?", with: "")
    }

    /// Full sentence, no beep: fetch from Google TTS (same URL as Vocabulary) and play.
    private func fetchAndPlayFullSentence() {
        let text = removeQuestionMarks(from: currentText).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            DispatchQueue.main.async { self.isPlaying = false }
            return
        }
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encoded)&tl=sv&client=tw-ob"
        guard let url = URL(string: urlString) else {
            playFallbackSound()
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if error != nil {
                    self.playFallbackSound()
                    return
                }
                guard let data = data, !data.isEmpty else {
                    self.playFallbackSound()
                    return
                }
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsPath.appendingPathComponent("full_\(UUID().uuidString).mp3")
                do {
                    try data.write(to: fileURL)
                    self.audioURL = fileURL
                    self.audioQueue = [fileURL]
                    self.currentQueueIndex = 0
                    self.audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                } catch {
                    self.playFallbackSound()
                }
            }
        }.resume()
    }

    private func generateAudioWithBeep(before: String, after: String) {
        // Generate TTS for before part
        // Remove question marks before encoding
        let beforeText = before.isEmpty ? " " : removeQuestionMarks(from: before)
        let encodedBefore = beforeText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let beforeURLString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedBefore)&tl=sv&client=tw-ob"

        guard let beforeURL = URL(string: beforeURLString) else {
            print("Failed to create before TTS URL")
            playFallbackSound()
            return
        }

        // Check if after part has meaningful content (not just punctuation)
        let cleanedAfter = removeQuestionMarks(from: after)
        let hasAfterContent = !cleanedAfter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Download before part
        let group = DispatchGroup()
        var beforeData: Data?
        var afterData: Data?

        group.enter()
        URLSession.shared.dataTask(with: beforeURL) { data, _, error in
            if let error = error {
                print("Before TTS error: \(error)")
            } else {
                beforeData = data
            }
            group.leave()
        }.resume()

        // Only download after part if it has meaningful content
        if hasAfterContent {
            let afterText = cleanedAfter
            let encodedAfter = afterText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let afterURLString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedAfter)&tl=sv&client=tw-ob"

            guard let afterURL = URL(string: afterURLString) else {
                print("Failed to create after TTS URL")
                playFallbackSound()
                return
            }

            group.enter()
            URLSession.shared.dataTask(with: afterURL) { data, _, error in
                if let error = error {
                    print("After TTS error: \(error)")
                } else {
                    afterData = data
                }
                group.leave()
            }.resume()
        } else {
            // No after content, set to nil so we skip it
            afterData = nil
        }

        group.notify(queue: .main) {
            guard let before = beforeData else {
                print("Failed to download before TTS")
                self.playFallbackSound()
                return
            }

            // Create beep sound (0.5 second, 440Hz tone)
            let beepData = self.createBeepSound(duration: 0.5, frequency: 440.0)

            // Combine audio files (afterData can be nil if no after content)
            let after = afterData ?? Data()
            self.combineAudioFiles(before: before, beep: beepData, after: after)
        }
    }

    private func createBeepSound(duration: Double, frequency: Double) -> Data {
        let sampleRate = 44100.0
        let numberOfSamples = Int(sampleRate * duration)
        var audioData = Data()

        for i in 0..<numberOfSamples {
            let sample = sin(2.0 * Double.pi * frequency * Double(i) / sampleRate)
            let intSample = Int16(sample * Double(Int16.max) * 0.3) // 30% volume
            withUnsafeBytes(of: intSample.littleEndian) { audioData.append(contentsOf: $0) }
        }

        // Create WAV header
        let header = createWAVHeader(dataSize: audioData.count, sampleRate: Int(sampleRate), channels: 1)
        return header + audioData
    }

    private func createWAVHeader(dataSize: Int, sampleRate: Int, channels: Int) -> Data {
        var header = Data()
        let bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let fileSize = 36 + dataSize

        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        header.append("WAVE".data(using: .ascii)!)

        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // fmt chunk size
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // audio format (PCM)
        header.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })

        // data chunk
        header.append("data".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        return header
    }

    private func combineAudioFiles(before: Data, beep: Data, after: Data) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        // Save individual files temporarily
        let beforeURL = documentsPath.appendingPathComponent("before_\(UUID().uuidString).mp3")
        let beepURL = documentsPath.appendingPathComponent("beep_\(UUID().uuidString).wav")

        do {
            try before.write(to: beforeURL)
            try beep.write(to: beepURL)

            // Create queue - only include after if it has content
            var queue: [URL] = [beforeURL, beepURL]

            if !after.isEmpty {
                let afterURL = documentsPath.appendingPathComponent("after_\(UUID().uuidString).mp3")
                try after.write(to: afterURL)
                queue.append(afterURL)
            }

            // Create queue for sequential playback
            audioQueue = queue
            currentQueueIndex = 0

            // Start playing the first file
            playNextInQueue()

        } catch {
            print("Error saving audio files: \(error)")
            playFallbackSound()
        }
    }

    private func playNextInQueue() {
        guard currentQueueIndex < audioQueue.count else {
            // All files played
            DispatchQueue.main.async {
                self.isPlaying = false
                // Clean up temp files
                for url in self.audioQueue {
                    try? FileManager.default.removeItem(at: url)
                }
                self.audioQueue = []
                self.currentQueueIndex = 0
            }
            return
        }

        let url = audioQueue[currentQueueIndex]

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            audioURL = url
        } catch {
            print("Error playing audio file: \(error)")
            playFallbackSound()
        }
    }

    private func playFallbackSound() {
        print("Playing fallback system sound")
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isPlaying = false
        }
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentQueueIndex += 1
        if currentQueueIndex < audioQueue.count {
            playNextInQueue()
        } else {
            DispatchQueue.main.async {
                self.isPlaying = false
                for url in self.audioQueue {
                    try? FileManager.default.removeItem(at: url)
                }
                self.audioQueue = []
                self.currentQueueIndex = 0
            }
        }
    }
}
