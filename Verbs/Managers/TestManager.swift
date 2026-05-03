//
//  TestManager.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import Foundation
import Combine

class TestManager: ObservableObject {
    static let shared = TestManager()
    
    @Published var tests: [Test] = []
    
    private let testsKey = "savedTests"
    
    private init() {
        loadTests()
    }
    
    func addTest(verbs: [Verb]) {
        let now = Date()
        // Use the first verb's base form + " Test" as the test name
        let firstVerb = verbs.first?.base.capitalized ?? ""
        let testName = firstVerb.isEmpty ? "Test" : "\(firstVerb) Test"
        
        let newTest = Test(
            name: testName,
            verbs: verbs,
            createdAt: now
        )
        
        tests.insert(newTest, at: 0)
        saveTests()
    }
    
    func deleteTest(_ test: Test) {
        tests.removeAll { $0.id == test.id }
        saveTests()
    }
    
    func clearAllTests() {
        tests = []
        saveTests()
    }
    
    func updateVerbScore(testId: String, verbId: String, score: Int) {
        if let index = tests.firstIndex(where: { $0.id == testId }) {
            var updatedTest = tests[index]
            updatedTest.verbScores[verbId] = score
            
            // Calculate total percentage if all verbs are completed
            if updatedTest.isCompleted {
                updatedTest.totalScorePercentage = updatedTest.calculatedPercentage
            }
            
            tests[index] = updatedTest
            saveTests()
        }
    }
    
    func updateVerbAnswers(testId: String, verbId: String, answers: [String: String], results: [String: Bool]) {
        if let index = tests.firstIndex(where: { $0.id == testId }) {
            var updatedTest = tests[index]
            updatedTest.verbAnswers[verbId] = answers
            updatedTest.verbResults[verbId] = results
            
            // Calculate score based on results
            let score = results.values.filter { $0 }.count
            updatedTest.verbScores[verbId] = score
            
            // Calculate total percentage if all verbs are completed
            if updatedTest.isCompleted {
                updatedTest.totalScorePercentage = updatedTest.calculatedPercentage
            }
            
            tests[index] = updatedTest
            saveTests()
        }
    }
    
    func getVerbAnswers(testId: String, verbId: String) -> ([String: String], [String: Bool]) {
        if let test = tests.first(where: { $0.id == testId }) {
            let answers = test.verbAnswers[verbId] ?? [:]
            let results = test.verbResults[verbId] ?? [:]
            return (answers, results)
        }
        return ([:], [:])
    }
    
    func saveTests() {
        do {
            let encoded = try JSONEncoder().encode(tests)
            UserDefaults.standard.set(encoded, forKey: testsKey)
        } catch {
            print("Failed to save tests: \(error)")
        }
    }
    
    private func loadTests() {
        if let data = UserDefaults.standard.data(forKey: testsKey) {
            do {
                let decoded = try JSONDecoder().decode([Test].self, from: data)
                // Sort by creation date, newest first
                tests = decoded.sorted { $0.createdAt > $1.createdAt }
            } catch {
                print("Failed to load tests: \(error)")
                tests = []
            }
        } else {
            tests = []
        }
    }
}

