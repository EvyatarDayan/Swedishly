//
//  TestResultsManager.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import Foundation
import Combine

class TestResultsManager: ObservableObject {
    @Published var results: [TestResult] = []
    private let resultsKey = "SavedTestResults"
    
    init() {
        loadResults()
    }
    
    func saveResult(_ result: TestResult) {
        results.insert(result, at: 0) // Add to beginning
        saveResults()
    }
    
    func deleteResult(_ result: TestResult) {
        results.removeAll { $0.id == result.id }
        saveResults()
    }
    
    func clearAllResults() {
        results.removeAll()
        saveResults()
    }
    
    private func saveResults() {
        if let encoded = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(encoded, forKey: resultsKey)
        }
    }
    
    private func loadResults() {
        if let data = UserDefaults.standard.data(forKey: resultsKey),
           let decoded = try? JSONDecoder().decode([TestResult].self, from: data) {
            results = decoded.sorted { $0.date > $1.date } // Most recent first
        }
    }
}
