import Foundation
import Combine

struct MyListWord: Identifiable, Codable {
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

class MyListManager: ObservableObject {
    static let shared = MyListManager()
    
    @Published private var myListWords: [MyListWord] = []
    
    private let myListKey = "myListWords"
    
    private init() {
        loadMyList()
    }
    
    func addToMyList(swedish: String, english: String) {
        // Check if word already exists
        if !myListWords.contains(where: { word in
            word.swedish.lowercased() == swedish.lowercased() &&
            word.english.lowercased() == english.lowercased()
        }) {
            let newWord = MyListWord(swedish: swedish, english: english)
            myListWords.append(newWord)
            saveMyList()
        }
    }
    
    func removeFromMyList(swedish: String, english: String) {
        let initialCount = myListWords.count
        myListWords.removeAll { word in
            word.swedish.lowercased() == swedish.lowercased() &&
            word.english.lowercased() == english.lowercased()
        }
        
        if myListWords.count < initialCount {
            saveMyList()
        }
    }
    
    func isInMyList(swedish: String, english: String) -> Bool {
        return myListWords.contains { word in
            word.swedish.lowercased() == swedish.lowercased() &&
            word.english.lowercased() == english.lowercased()
        }
    }
    
    func getMyListWords() -> [MyListWord] {
        return myListWords.sorted { $0.dateAdded > $1.dateAdded } // Most recent first
    }
    
    func getMyListCount() -> Int {
        return myListWords.count
    }
    
    // MARK: - Session cache for "All words" (Words list)
    // Loaded once per app launch, kept in memory so Words list opens instantly.
    private var cachedAllWords: [MyListWord]?
    
    /// Returns all words from the vocabulary data as MyListWord, building the list once and reusing for the rest of the app session.
    func getAllWordsCached() -> [MyListWord] {
        if let cached = cachedAllWords { return cached }
        let words = TestDataManager.shared.getAllWords()
        let list = words.map { t in MyListWord(swedish: t.swedish, english: t.english) }
        cachedAllWords = list
        return list
    }
    
    /// Number of all words (uses cache when available).
    func getAllWordsCount() -> Int {
        if cachedAllWords != nil { return cachedAllWords!.count }
        return TestDataManager.shared.getAllWords().count
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
            myListWords = try JSONDecoder().decode([MyListWord].self, from: data)
        } catch {
            print("❌ Failed to load my list: \(error)")
            myListWords = []
        }
    }
}
