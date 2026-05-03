import Foundation
import Combine

class TestHistoryManager: ObservableObject {
    static let shared = TestHistoryManager()
    
    @Published var historyItems: [TestHistoryItem] = []
    
    private let historyKey = "testHistory"
    
    private init() {
        loadHistory()
    }
    
    func addHistoryItem(_ item: TestHistoryItem) {
        historyItems.insert(item, at: 0) // Add to beginning (most recent first)
        saveHistory()
    }
    
    func deleteHistoryItem(_ item: TestHistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(historyItems)
            UserDefaults.standard.set(encoded, forKey: historyKey)
        } catch {
            print("❌ Failed to save history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return
        }
        
        do {
            historyItems = try JSONDecoder().decode([TestHistoryItem].self, from: data)
            // Sort by date (most recent first)
            historyItems.sort { $0.dateTaken > $1.dateTaken }
        } catch {
            print("❌ Failed to load history: \(error)")
            historyItems = []
        }
    }
    
    func clearAllHistory() {
        historyItems = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}
