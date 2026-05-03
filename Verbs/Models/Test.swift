//
//  Test.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import Foundation

struct Test: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let verbs: [Verb]
    let createdAt: Date
    var verbScores: [String: Int] // verb id -> score (0-3)
    var totalScorePercentage: Int? // Overall test score as percentage (0-100)
    var verbAnswers: [String: [String: String]] = [:] // verb id -> ["Present": answer, "Past": answer, "Perfect": answer]
    var verbResults: [String: [String: Bool]] = [:] // verb id -> ["Present": isCorrect, "Past": isCorrect, "Perfect": isCorrect]
    
    init(name: String, verbs: [Verb], createdAt: Date = Date(), verbScores: [String: Int] = [:], totalScorePercentage: Int? = nil, verbAnswers: [String: [String: String]] = [:], verbResults: [String: [String: Bool]] = [:]) {
        self.name = name
        self.verbs = verbs
        self.createdAt = createdAt
        self.verbScores = verbScores
        self.totalScorePercentage = totalScorePercentage
        self.verbAnswers = verbAnswers
        self.verbResults = verbResults
    }
    
    static func == (lhs: Test, rhs: Test) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case name, verbs, createdAt, verbScores, totalScorePercentage, verbAnswers, verbResults
    }
    
    var isCompleted: Bool {
        // Test is completed when all verbs have scores
        verbs.count > 0 && verbScores.count == verbs.count
    }
    
    var calculatedPercentage: Int {
        guard verbs.count > 0 else { return 0 }
        let totalPossible = verbs.count * 3 // 3 questions per verb
        let totalCorrect = verbScores.values.reduce(0, +)
        return Int((Double(totalCorrect) / Double(totalPossible)) * 100)
    }
}

