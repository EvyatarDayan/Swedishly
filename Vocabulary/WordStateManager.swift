import Foundation
import Combine

enum WordState: String, Codable {
    case new = "new"
    case learning = "learning"
    case review = "review"
    case weak = "weak"
    case mastered = "mastered"
}

struct WordStateData: Codable, Identifiable {
    let id: UUID
    let swedish: String
    let english: String
    var state: WordState
    var correctCount: Int
    var wrongCount: Int
    var lastSeen: Date?
    var lastCorrect: Date?
    
    init(swedish: String, english: String, state: WordState = .new, correctCount: Int = 0, wrongCount: Int = 0) {
        self.id = UUID()
        self.swedish = swedish
        self.english = english
        self.state = state
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.lastSeen = nil
        self.lastCorrect = nil
    }
    
    static func == (lhs: WordStateData, rhs: WordStateData) -> Bool {
        return lhs.id == rhs.id
    }
}

class WordStateManager: ObservableObject {
    static let shared = WordStateManager()
    
    @Published private var wordStates: [WordStateData] = []
    
    private let wordStatesKey = "wordStates"
    
    private init() {
        loadWordStates()
        // Migrate existing wrong answers to weak state
        migrateWrongAnswers()
    }
    
    // Migrate existing wrong answers from WrongAnswersManager to weak state
    private func migrateWrongAnswers() {
        let wrongAnswers = WrongAnswersManager.shared.getWrongAnswerWords()
        var needsSave = false
        
        for wrongWord in wrongAnswers {
            if !wordStates.contains(where: { $0.swedish.lowercased() == wrongWord.swedish.lowercased() && $0.english.lowercased() == wrongWord.english.lowercased() }) {
                var stateData = WordStateData(
                    swedish: wrongWord.swedish,
                    english: wrongWord.english,
                    state: .weak,
                    correctCount: wrongWord.correctCount,
                    wrongCount: wrongWord.wrongCount
                )
                stateData.lastSeen = Date()
                wordStates.append(stateData)
                needsSave = true
            }
        }
        
        if needsSave {
            saveWordStates()
        }
    }
    
    func getWordState(swedish: String, english: String) -> WordState {
        if let stateData = wordStates.first(where: { 
            $0.swedish.lowercased() == swedish.lowercased() && 
            $0.english.lowercased() == english.lowercased() 
        }) {
            return stateData.state
        }
        return .new
    }
    
    func recordAnswer(swedish: String, english: String, isCorrect: Bool) {
        let key = (swedish.lowercased(), english.lowercased())
        
        if let index = wordStates.firstIndex(where: { 
            $0.swedish.lowercased() == key.0 && 
            $0.english.lowercased() == key.1 
        }) {
            var stateData = wordStates[index]
            stateData.lastSeen = Date()
            
            if isCorrect {
                stateData.correctCount += 1
                stateData.lastCorrect = Date()
            } else {
                stateData.wrongCount += 1
                // Reset correct count if wrong answer (prevents quick advancement)
                // Only reset if wrong count becomes significantly higher
                if stateData.wrongCount > stateData.correctCount + 1 {
                    stateData.correctCount = max(0, stateData.correctCount - 1)
                }
            }
            
            // Update state based on performance
            stateData.state = calculateState(correctCount: stateData.correctCount, wrongCount: stateData.wrongCount)
            wordStates[index] = stateData
        } else {
            // New word - first time seen
            var stateData = WordStateData(
                swedish: swedish,
                english: english,
                state: .learning,
                correctCount: isCorrect ? 1 : 0,
                wrongCount: isCorrect ? 0 : 1
            )
            stateData.lastSeen = Date()
            if isCorrect {
                stateData.lastCorrect = Date()
            }
            stateData.state = calculateState(correctCount: stateData.correctCount, wrongCount: stateData.wrongCount)
            wordStates.append(stateData)
        }
        
        saveWordStates()
    }
    
    // Track when a word is shown (not just answered)
    func markWordAsSeen(swedish: String, english: String) {
        let key = (swedish.lowercased(), english.lowercased())
        
        if let index = wordStates.firstIndex(where: { 
            $0.swedish.lowercased() == key.0 && 
            $0.english.lowercased() == key.1 
        }) {
            var stateData = wordStates[index]
            stateData.lastSeen = Date()
            wordStates[index] = stateData
            saveWordStates()
        }
    }
    
    private func calculateState(correctCount: Int, wrongCount: Int) -> WordState {
        let total = correctCount + wrongCount
        
        if total == 0 {
            return .new
        }
        
        let correctRatio = Double(correctCount) / Double(total)
        
        // weak: wrongCount > correctCount or wrongCount >= 3
        if wrongCount > correctCount || wrongCount >= 3 {
            return .weak
        }
        
        // mastered: correctRatio >= 0.9 and total >= 8 (increased from 5 for more practice)
        if correctRatio >= 0.9 && total >= 8 {
            return .mastered
        }
        
        // review: correctRatio >= 0.75 and total >= 5 (increased threshold and count)
        if correctRatio >= 0.75 && total >= 5 {
            return .review
        }
        
        // learning: seen but not meeting other criteria
        return .learning
    }
    
    func getWordsByState(_ state: WordState, count: Int? = nil) -> [WordStateData] {
        let filtered = wordStates.filter { $0.state == state }
        if let count = count {
            return Array(filtered.shuffled().prefix(count))
        }
        return filtered
    }
    
    func getWordsForPractice(excludingRecentlySeen: Set<String> = [], minTimeSinceLastSeen: TimeInterval = 300) -> [WordStateData] {
        // Priority: weak > learning > review > new > mastered
        // Exclude words seen recently (within minTimeSinceLastSeen seconds, default 5 minutes)
        let now = Date()
        var result: [WordStateData] = []
        
        // Filter function to exclude recently seen words
        let isAvailable: (WordStateData) -> Bool = { word in
            // Exclude if in the exclusion set
            let key = "\(word.swedish.lowercased()):\(word.english.lowercased())"
            if excludingRecentlySeen.contains(key) {
                return false
            }
            
            // Exclude if seen too recently (within cooldown period)
            if let lastSeen = word.lastSeen {
                let timeSinceSeen = now.timeIntervalSince(lastSeen)
                if timeSinceSeen < minTimeSinceLastSeen {
                    return false
                }
            }
            
            return true
        }
        
        // Get weak words (highest priority) - always include if available
        let weakWords = getWordsByState(.weak).filter(isAvailable)
        result.append(contentsOf: weakWords.shuffled())
        
        // Get learning words - exclude if seen within last 2 minutes
        let learningWords = getWordsByState(.learning).filter { word in
            guard isAvailable(word) else { return false }
            if let lastSeen = word.lastSeen {
                return now.timeIntervalSince(lastSeen) >= 120 // 2 minutes cooldown
            }
            return true
        }
        result.append(contentsOf: learningWords.shuffled())
        
        // Get review words - exclude if seen within last 10 minutes (needs more spacing)
        let reviewWords = getWordsByState(.review).filter { word in
            guard isAvailable(word) else { return false }
            if let lastSeen = word.lastSeen {
                return now.timeIntervalSince(lastSeen) >= 600 // 10 minutes cooldown
            }
            return true
        }
        result.append(contentsOf: reviewWords.shuffled())
        
        // Shuffle and return (mastered words are excluded from practice)
        return result.shuffled()
    }
    
    func getAllWordStates() -> [WordStateData] {
        return wordStates
    }
    
    private func saveWordStates() {
        do {
            let encoded = try JSONEncoder().encode(wordStates)
            UserDefaults.standard.set(encoded, forKey: wordStatesKey)
        } catch {
            print("❌ Failed to save word states: \(error)")
        }
    }
    
    private func loadWordStates() {
        guard let data = UserDefaults.standard.data(forKey: wordStatesKey) else {
            return
        }
        
        do {
            wordStates = try JSONDecoder().decode([WordStateData].self, from: data)
        } catch {
            print("❌ Failed to load word states: \(error)")
            wordStates = []
        }
    }
    
    func clearAllWordStates() {
        wordStates = []
        UserDefaults.standard.removeObject(forKey: wordStatesKey)
    }
}
