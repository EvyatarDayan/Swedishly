//
//  TestResult.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import Foundation

struct TestResult: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let score: Int
    let totalQuestions: Int
    let percentage: Double
    let testType: String // "Verbs", "Pronouns", "Noun Gender", or "Reflexiva pronomen"
    let verbQuestions: [Exercise]? // Questions for verb tests
    let pronounQuestions: [PronounExercise]? // Questions for pronoun tests
    let nounGenderQuestions: [NounGenderExercise]? // Questions for noun gender tests
    let reflexiveQuestions: [Exercise]? // Questions for reflexive pronomen tests
    let questionResults: [Int: Bool] // Track which questions were answered correctly (index: isCorrect)
    
    init(score: Int, totalQuestions: Int, testType: String, verbQuestions: [Exercise]? = nil, pronounQuestions: [PronounExercise]? = nil, nounGenderQuestions: [NounGenderExercise]? = nil, reflexiveQuestions: [Exercise]? = nil, questionResults: [Int: Bool] = [:]) {
        self.id = UUID()
        self.date = Date()
        self.score = score
        self.totalQuestions = totalQuestions
        self.percentage = Double(score) / Double(totalQuestions) * 100.0
        self.testType = testType
        self.verbQuestions = verbQuestions
        self.pronounQuestions = pronounQuestions
        self.nounGenderQuestions = nounGenderQuestions
        self.reflexiveQuestions = reflexiveQuestions
        self.questionResults = questionResults
    }
}
