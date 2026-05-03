import Foundation
import Combine

class WrongAnswersManager: ObservableObject {
    static let shared = WrongAnswersManager()
    
    @Published private var wrongAnswerWords: [WrongAnswerWord] = []
    
    private let wrongAnswersKey = "wrongAnswers"
    
    private init() {
        loadWrongAnswers()
    }
    
    func addWrongAnswer(swedish: String, english: String) {
        if let index = wrongAnswerWords.firstIndex(where: { word in
            word.swedish.lowercased() == swedish.lowercased() &&
            word.english.lowercased() == english.lowercased()
        }) {
            // Word already exists, increment wrong count
            var updatedWord = wrongAnswerWords[index]
            updatedWord.wrongCount += 1
            wrongAnswerWords[index] = updatedWord
        } else {
            // New wrong answer
            let newWord = WrongAnswerWord(swedish: swedish, english: english, wrongCount: 1)
            wrongAnswerWords.append(newWord)
        }
        saveWrongAnswers()
    }
    
    func recordCorrectAnswer(swedish: String, english: String) {
        if let index = wrongAnswerWords.firstIndex(where: { word in
            word.swedish.lowercased() == swedish.lowercased() &&
            word.english.lowercased() == english.lowercased()
        }) {
            // Increment correct count
            var updatedWord = wrongAnswerWords[index]
            updatedWord.correctCount += 1
            wrongAnswerWords[index] = updatedWord
            saveWrongAnswers()
        }
    }
    
    func getWrongAnswerWords() -> [WrongAnswerWord] {
        return wrongAnswerWords
    }
    
    func getRandomWrongAnswerWords(count: Int) -> [WrongAnswerWord] {
        // Filter words that have more wrong answers than correct answers
        let problematicWords = wrongAnswerWords.filter { $0.wrongCount > $0.correctCount }
        
        guard problematicWords.count > 0 else {
            return []
        }
        
        let shuffled = problematicWords.shuffled()
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }
    
    private func saveWrongAnswers() {
        do {
            let encoded = try JSONEncoder().encode(wrongAnswerWords)
            UserDefaults.standard.set(encoded, forKey: wrongAnswersKey)
        } catch {
            print("❌ Failed to save wrong answers: \(error)")
        }
    }
    
    private func loadWrongAnswers() {
        guard let data = UserDefaults.standard.data(forKey: wrongAnswersKey) else {
            return
        }
        
        do {
            wrongAnswerWords = try JSONDecoder().decode([WrongAnswerWord].self, from: data)
        } catch {
            print("❌ Failed to load wrong answers: \(error)")
            wrongAnswerWords = []
        }
    }
    
    func getWrongAnswerCount() -> Int {
        return wrongAnswerWords.count
    }
    
    func clearAllWrongAnswers() {
        wrongAnswerWords = []
        UserDefaults.standard.removeObject(forKey: wrongAnswersKey)
        print("🗑️ Cleared all wrong answers")
    }
    
    func removeWrongAnswer(swedish: String, english: String) {
        let initialCount = wrongAnswerWords.count
        wrongAnswerWords.removeAll { word in
            word.swedish.lowercased() == swedish.lowercased() &&
            word.english.lowercased() == english.lowercased()
        }
        
        if wrongAnswerWords.count < initialCount {
            saveWrongAnswers()
            print("✅ Removed wrong answer: \(swedish) - \(english)")
        }
    }
}
