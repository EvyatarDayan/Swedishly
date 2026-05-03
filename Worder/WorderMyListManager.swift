//
//  WorderMyListManager.swift
//  Swedishly
//

import Foundation
import Combine

struct WorderMyListWord: Identifiable, Codable {
    let id: UUID
    let swedish: String
    let english: String
    let dateAdded: Date
    
    init(swedish: String, english: String) {
        self.id = UUID()
        self.swedish = swedish
        self.english = english
        self.dateAdded = Date()
    }
}

// Helper: normalize whitespace to single spaces for comparisons
private extension String {
    var singleSpaced: String {
        let pattern = "\\s+"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(self.startIndex..., in: self)
            let replaced = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: " ")
            return replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class WorderMyListManager: ObservableObject {
    static let shared = WorderMyListManager()
    
    @Published private var myListWords: [WorderMyListWord] = []
    
    private let myListKey = "worderMyListWords"
    
    private init() {
        loadMyList()
    }
    
    func addToMyList(swedish: String, english: String) {
        let normSwedish = swedish.singleSpaced.lowercased()
        let normEnglish = english.singleSpaced.lowercased()
        if !myListWords.contains(where: { word in
            word.swedish.singleSpaced.lowercased() == normSwedish &&
            word.english.singleSpaced.lowercased() == normEnglish
        }) {
            let newWord = WorderMyListWord(swedish: swedish.singleSpaced, english: english.singleSpaced)
            myListWords.append(newWord)
            saveMyList()
        }
    }
    
    func removeFromMyList(swedish: String, english: String) {
        let normSwedish = swedish.singleSpaced.lowercased()
        let normEnglish = english.singleSpaced.lowercased()
        let initialCount = myListWords.count
        myListWords.removeAll { word in
            word.swedish.singleSpaced.lowercased() == normSwedish &&
            word.english.singleSpaced.lowercased() == normEnglish
        }

        if myListWords.count < initialCount {
            saveMyList()
        }
    }
    
    func isInMyList(swedish: String, english: String) -> Bool {
        let normSwedish = swedish.singleSpaced.lowercased()
        let normEnglish = english.singleSpaced.lowercased()
        return myListWords.contains { word in
            word.swedish.singleSpaced.lowercased() == normSwedish &&
            word.english.singleSpaced.lowercased() == normEnglish
        }
    }
    
    func getMyListWords() -> [WorderMyListWord] {
        return myListWords.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    func getMyListCount() -> Int {
        return myListWords.count
    }
    
    // MARK: - Session cache for "All sentences" (My List)
    // Loaded once per app launch, kept in memory so My List opens instantly.
    private var cachedAllSentences: [WorderMyListWord]?
    
    /// Returns all sentences from the word-order data, building the list once and reusing for the rest of the app session.
    func getAllSentencesCached() -> [WorderMyListWord] {
        if let cached = cachedAllSentences { return cached }
        let examples = WordOrderDataManager.shared.getAllExamples()
        let list = examples.map { ex in
            WorderMyListWord(swedish: ex.answer.singleSpaced, english: ex.answerTranslation.singleSpaced)
        }
        cachedAllSentences = list
        return list
    }
    
    /// Number of all sentences (uses cache when available, does not build full list).
    func getAllSentencesCount() -> Int {
        if cachedAllSentences != nil { return cachedAllSentences!.count }
        return WordOrderDataManager.shared.getAllExamples().count
    }
    
    func clearMyList() {
        myListWords = []
        UserDefaults.standard.removeObject(forKey: myListKey)
    }
    
    private func saveMyList() {
        do {
            let encoded = try JSONEncoder().encode(myListWords)
            UserDefaults.standard.set(encoded, forKey: myListKey)
        } catch {
            print("❌ Failed to save my list: \(error)")
        }
    }
    
    private func loadMyList() {
        guard let data = UserDefaults.standard.data(forKey: myListKey) else {
            return
        }
        
        do {
            myListWords = try JSONDecoder().decode([WorderMyListWord].self, from: data)
        } catch {
            print("❌ Failed to load my list: \(error)")
            myListWords = []
        }
    }
}
