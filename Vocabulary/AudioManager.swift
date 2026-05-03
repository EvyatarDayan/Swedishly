import Foundation
import AVFoundation
import AudioToolbox
import Combine

// MARK: - AudioManager
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var isAudioReady = false
    private var audioPlayer: AVAudioPlayer?
    private var audioURL: URL?
    private var currentText: String = ""
    private let ttsCacheFolderName = "tts_cache"
    
    func generateAudio(for text: String) {
        // Reset state
        isAudioReady = false
        isPlaying = false
        currentText = text
        
        print("Generating audio for: \(text)")
        
        // Check cache first
        let cachedURL = fileURLForText(text)
        audioURL = cachedURL
        if FileManager.default.fileExists(atPath: cachedURL.path) {
            // Cached audio exists
            isAudioReady = true
            print("Using cached TTS for: \(text)")
            return
        }

        // Use Apple's built-in TTS with better voice selection (prepares audio session)
        generateTTSAudio(for: text)
    }
    
    func playAudio() {
        guard !isPlaying, isAudioReady else { 
            print("Cannot play audio - isPlaying: \(isPlaying), isReady: \(isAudioReady)")
            return 
        }
        
        print("Playing TTS audio...")
        isPlaying = true
        
        // Try web-based TTS first, then fallback to system sound
        playWebTTS()
    }
    
    func cleanupAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isAudioReady = false
        
        // Do not delete cached audio. Just clear reference.
        audioURL = nil
    }
    
    private func generateTTSAudio(for text: String) {
        print("Generating TTS audio for: \(text)")
        
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
        
        // Use direct speech synthesis instead of file generation
        // This avoids the problematic write method and pipe errors
        // After session configured, fetch remote TTS and save to cache (async)
        fetchAndCacheTTS(for: text)
    }
    
    private func playWebTTS() {
        // If cached file exists, play it
        if let cached = audioURL, FileManager.default.fileExists(atPath: cached.path) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: cached)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Error playing cached audio: \(error)")
                playFallbackSound()
            }
            return
        }
        // Fallback: try to fetch remote TTS and cache it (handled in fetchAndCacheTTS)
        playFallbackSound()
    }

    // Fetch TTS from remote and save into cache file
    private func fetchAndCacheTTS(for text: String) {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&q=\(encodedText)&tl=sv&client=tw-ob"
        guard let url = URL(string: urlString) else {
            print("Failed to create TTS URL")
            self.isAudioReady = false
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("TTS network error: \(error)")
                    self.isAudioReady = false
                    return
                }
                guard let data = data, !data.isEmpty else {
                    print("No TTS data received")
                    self.isAudioReady = false
                    return
                }
                // Ensure cache folder exists
                let cacheDir = self.ttsCacheDirectory()
                try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
                let fileURL = self.fileURLForText(self.currentText)
                do {
                    try data.write(to: fileURL, options: .atomic)
                    self.audioURL = fileURL
                    self.isAudioReady = true
                    // Auto-play if generated after user requested play
                    if self.isPlaying {
                        self.playWebTTS()
                    }
                } catch {
                    print("Failed to write TTS to cache: \(error)")
                    self.isAudioReady = false
                }
            }
        }
        task.resume()
    }

    // MARK: - Cache helpers
    private func ttsCacheDirectory() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent(ttsCacheFolderName, isDirectory: true)
    }

    private func fileURLForText(_ text: String) -> URL {
        let safe = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        return ttsCacheDirectory().appendingPathComponent("\(safe).mp3")
    }

    func clearAudioCache() {
        let dir = ttsCacheDirectory()
        if FileManager.default.fileExists(atPath: dir.path) {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
                for f in files {
                    let p = dir.appendingPathComponent(f).path
                    try FileManager.default.removeItem(atPath: p)
                }
                print("Cleared TTS audio cache")
            } catch {
                print("Failed clearing TTS cache: \(error)")
            }
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
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
