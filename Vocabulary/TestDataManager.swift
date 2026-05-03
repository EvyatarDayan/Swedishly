import Foundation
import Combine

class TestDataManager: ObservableObject {
    static let shared = TestDataManager()
    
    private var words: [TestWord] = []
    private var wordsByKey: [String: TestWord] = [:]
    
    private init() {
        loadWords()
    }
    
    private func loadWords() {
        // If words already loaded, skip re-loading to avoid repeated logs/work
        if !words.isEmpty { return }

        // Try Vocabulary/Data/VocabularyWords.json first, then VocabularyWords.json, then testWords.json
        let url = Bundle.main.url(forResource: "VocabularyWords", withExtension: "json", subdirectory: "Vocabulary/Data")
            ?? Bundle.main.url(forResource: "VocabularyWords", withExtension: "json")
            ?? Bundle.main.url(forResource: "testWords", withExtension: "json")

        guard let url = url else {
            print("❌ Could not find VocabularyWords.json or testWords.json in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            words = try JSONDecoder().decode([TestWord].self, from: data)
#if DEBUG
            print("✅ Loaded \(words.count) words from \(url.lastPathComponent)")
#endif
            // Build lookup dictionary for fast access by content (lowercased key)
            wordsByKey = Dictionary(uniqueKeysWithValues: words.map { (keyForWord($0.swedish, $0.english), $0) })
        } catch {
            print("❌ Failed to load words: \(error)")
        }
    }
    
    func getRandomWords(count: Int, excludingWords: [(swedish: String, english: String)] = []) -> [TestWord] {
        let excludedSet = Set(excludingWords.map { "\($0.swedish.lowercased()):\($0.english.lowercased())" })
        
        let availableWords = words.filter { word in
            let key = "\(word.swedish.lowercased()):\(word.english.lowercased())"
            return !excludedSet.contains(key)
        }
        
        guard availableWords.count >= count else {
            print("⚠️ Not enough words available. Requested: \(count), Available: \(availableWords.count)")
            return Array(availableWords.shuffled().prefix(count))
        }
        
        return Array(availableWords.shuffled().prefix(count))
    }
    
    func getWordsByContent(swedish: String, english: String) -> TestWord? {
        let key = keyForWord(swedish, english)
        return wordsByKey[key]
    }
    
    func getAllWords() -> [TestWord] {
        return words
    }

    private func keyForWord(_ swedish: String, _ english: String) -> String {
        return "\(swedish.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()):\(english.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }
}
