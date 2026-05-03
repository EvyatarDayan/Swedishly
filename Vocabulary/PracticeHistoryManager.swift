import Foundation
import Combine

class PracticeHistoryManager: ObservableObject {
    static let shared = PracticeHistoryManager()
    
    @Published var historyItems: [PracticeHistoryItem] = []
    
    private let historyKey = "practiceHistory"
    
    private init() {
        loadHistory()
    }
    
    func addHistoryItem(_ item: PracticeHistoryItem) {
        historyItems.insert(item, at: 0) // Add to beginning (most recent first)
        saveHistory()
    }
    
    func deleteHistoryItem(_ item: PracticeHistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(historyItems)
            UserDefaults.standard.set(encoded, forKey: historyKey)
        } catch {
            print("❌ Failed to save practice history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return
        }
        
        do {
            historyItems = try JSONDecoder().decode([PracticeHistoryItem].self, from: data)
            // Sort by date (most recent first)
            historyItems.sort { $0.dateTaken > $1.dateTaken }
        } catch {
            print("❌ Failed to load practice history: \(error)")
            historyItems = []
        }
    }
    
    func clearAllHistory() {
        historyItems = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}
