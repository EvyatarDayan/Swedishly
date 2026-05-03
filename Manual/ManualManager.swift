//
//  ManualManager.swift
//  Swedishly
//

import Foundation
import Combine

// MARK: - ManualManager
class ManualManager: ObservableObject {
    static let shared = ManualManager()
    
    @Published var manualSentences: [Sentence] = []
    
    private init() {
        loadManualSentences()
    }
    
    func addManualSentence(_ sentence: Sentence) {
        let sentenceWithDate = Sentence(
            id: sentence.id,
            swedish: sentence.swedish,
            english: sentence.english,
            dateCreated: sentence.dateCreated ?? Date()
        )
        manualSentences.append(sentenceWithDate)
        saveManualSentences()
    }
    
    func removeManualSentence(_ sentence: Sentence) {
        manualSentences.removeAll { $0.id == sentence.id }
        saveManualSentences()
    }
    
    func updateManualSentence(_ updatedSentence: Sentence) {
        if let index = manualSentences.firstIndex(where: { $0.id == updatedSentence.id }) {
            let originalSentence = manualSentences[index]
            let sentenceWithDate = Sentence(
                id: updatedSentence.id,
                swedish: updatedSentence.swedish,
                english: updatedSentence.english,
                dateCreated: updatedSentence.dateCreated ?? originalSentence.dateCreated ?? Date()
            )
            manualSentences[index] = sentenceWithDate
            saveManualSentences()
        }
    }
    
    private func saveManualSentences() {
        do {
            let encoded = try JSONEncoder().encode(manualSentences)
            UserDefaults.standard.set(encoded, forKey: "manualSentences")
        } catch {
            print("❌ Failed to save manual sentences: \(error)")
        }
    }
    
    private func loadManualSentences() {
        if let data = UserDefaults.standard.data(forKey: "manualSentences") {
            do {
                let decoded = try JSONDecoder().decode([Sentence].self, from: data)
                manualSentences = decoded
            } catch {
                print("❌ Failed to load manual sentences: \(error)")
                manualSentences = []
            }
        }
    }
    
    func clearAllManualSentences() {
        manualSentences = []
        UserDefaults.standard.removeObject(forKey: "manualSentences")
    }
    
    func exportManualSentences() -> String? {
        guard let encoded = try? JSONEncoder().encode(manualSentences) else { return nil }
        return String(data: encoded, encoding: .utf8)
    }
    
    func importManualSentences(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Sentence].self, from: data) else { return false }
        manualSentences = decoded
        saveManualSentences()
        return true
    }
}
