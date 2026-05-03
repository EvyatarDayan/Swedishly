//
//  AdjectivesAudioManager.swift
//  Swedishly
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import AudioToolbox

class AdjectivesAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var isAudioReady = false
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    private var currentText: String = ""
    private var sentenceParts: (before: String, after: String)?
    private var audioQueue: [URL] = []
    private var currentQueueIndex = 0
    
    func generateAudio(for text: String, withBeepAt answer: String? = nil) {
        isAudioReady = false
        isPlaying = false
        currentText = text
        
        if let answer = answer, text.contains(answer) {
            if let range = text.range(of: answer) {
                let before = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let after = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                sentenceParts = (before: before, after: after)
            } else {
                sentenceParts = nil
            }
        } else {
            sentenceParts = nil
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            self.isAudioReady = false
            return
        }
        
        self.isAudioReady = true
    }
    
    func playAudio() {
        guard !isPlaying, isAudioReady else { return }
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
        let beforeText = before.isEmpty ? " " : removeQuestionMarks(from: before)
        let encodedBefore = beforeText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let beforeURLString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedBefore)&tl=sv&client=tw-ob"
        
        guard let beforeURL = URL(string: beforeURLString) else {
            playFallbackSound()
            return
        }
        
        let cleanedAfter = removeQuestionMarks(from: after)
        let hasAfterContent = !cleanedAfter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        let group = DispatchGroup()
        var beforeData: Data?
        var afterData: Data?
        
        group.enter()
        URLSession.shared.dataTask(with: beforeURL) { data, _, _ in
            beforeData = data
            group.leave()
        }.resume()
        
        if hasAfterContent {
            let encodedAfter = cleanedAfter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let afterURLString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedAfter)&tl=sv&client=tw-ob"
            if let afterURL = URL(string: afterURLString) {
                group.enter()
                URLSession.shared.dataTask(with: afterURL) { data, _, _ in
                    afterData = data
                    group.leave()
                }.resume()
            }
        }
        
        group.notify(queue: .main) {
            guard let before = beforeData else {
                self.playFallbackSound()
                return
            }
            let beepData = self.createBeepSound(duration: 0.5, frequency: 440.0)
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
            let intSample = Int16(sample * Double(Int16.max) * 0.3)
            withUnsafeBytes(of: intSample.littleEndian) { audioData.append(contentsOf: $0) }
        }
        let header = createWAVHeader(dataSize: audioData.count, sampleRate: Int(sampleRate), channels: 1)
        return header + audioData
    }
    
    private func createWAVHeader(dataSize: Int, sampleRate: Int, channels: Int) -> Data {
        var header = Data()
        let bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let fileSize = 36 + dataSize
        header.append("RIFF".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        header.append("WAVE".data(using: .ascii)!)
        header.append("fmt ".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })
        header.append("data".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        return header
    }
    
    private func combineAudioFiles(before: Data, beep: Data, after: Data) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let beforeURL = documentsPath.appendingPathComponent("before_\(UUID().uuidString).mp3")
        let beepURL = documentsPath.appendingPathComponent("beep_\(UUID().uuidString).wav")
        do {
            try before.write(to: beforeURL)
            try beep.write(to: beepURL)
            var queue: [URL] = [beforeURL, beepURL]
            if !after.isEmpty {
                let afterURL = documentsPath.appendingPathComponent("after_\(UUID().uuidString).mp3")
                try after.write(to: afterURL)
                queue.append(afterURL)
            }
            audioQueue = queue
            currentQueueIndex = 0
            playNextInQueue()
        } catch {
            playFallbackSound()
        }
    }
    
    private func playNextInQueue() {
        guard currentQueueIndex < audioQueue.count else {
            DispatchQueue.main.async {
                self.isPlaying = false
                for url in self.audioQueue { try? FileManager.default.removeItem(at: url) }
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
            playFallbackSound()
        }
    }
    
    private func playFallbackSound() {
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.isPlaying = false }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentQueueIndex += 1
        if currentQueueIndex < audioQueue.count {
            playNextInQueue()
        } else {
            DispatchQueue.main.async {
                self.isPlaying = false
                for url in self.audioQueue { try? FileManager.default.removeItem(at: url) }
                self.audioQueue = []
                self.currentQueueIndex = 0
            }
        }
    }
}
