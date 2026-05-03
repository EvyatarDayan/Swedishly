//
//  PronounQuizViewModel.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PronounQuizViewModel: ObservableObject {
    @Published var pronounData: PronounData?
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswer: Int? = nil
    @Published var selectedAnswerText: String? = nil
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    @Published var showResults: Bool = false
    @Published var testQuestions: [PronounExercise] = []
    @Published var correctAnswers: Int = 0
    @Published var questionResults: [Int: Bool] = [:] // Track which questions were answered correctly
    
    private let questionsPerTest = 10
    
    var currentQuestion: PronounExercise? {
        guard currentQuestionIndex < testQuestions.count else { return nil }
        return testQuestions[currentQuestionIndex]
    }
    
    var exercises: [PronounExercise] {
        pronounData?.exercises ?? []
    }
    
    var isTestComplete: Bool {
        currentQuestionIndex >= testQuestions.count && testQuestions.count > 0
    }
    
    var currentScore: Int {
        correctAnswers
    }
    
    var totalQuestions: Int {
        testQuestions.count
    }
    
    init() {
        loadQuestions()
    }
    
    func loadQuestions() {
        let url = Bundle.main.url(forResource: "pronounsData", withExtension: "json", subdirectory: "Grammar/Data")
            ?? Bundle.main.url(forResource: "pronounsData", withExtension: "json")
        guard let url = url else {
            print("Error: Could not find pronounsData.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PronounData.self, from: data)
            pronounData = decoded
        } catch {
            print("Error loading pronoun data: \(error.localizedDescription)")
        }
    }
    
    func startNewTest() {
        guard let allExercises = pronounData?.exercises, !allExercises.isEmpty else {
            print("Error: No exercises available or data not loaded")
            return
        }
        
        // Create a mutable copy and shuffle it to ensure true randomness
        var availableExercises = allExercises
        availableExercises.shuffle() // In-place shuffle for better randomness
        
        // Select 10 random questions from the shuffled array
        let selectedQuestions = Array(availableExercises.prefix(questionsPerTest))
        
        // Shuffle options for each question to ensure complete randomness
        testQuestions = selectedQuestions.map { question in
            var shuffledOptions = question.options
            shuffledOptions.shuffle() // In-place shuffle for better randomness
            // Answer remains the same (compared by string value, not index)
            return PronounExercise(
                id: question.id,
                sentence: question.sentence,
                basePronoun: question.basePronoun,
                options: shuffledOptions,
                answer: question.answer,
                rule: question.rule,
                level: question.level,
                translation: question.translation
            )
        }
        
        // Shuffle the test questions themselves for additional randomness
        testQuestions.shuffle()
        
        currentQuestionIndex = 0
        correctAnswers = 0
        selectedAnswer = nil
        selectedAnswerText = nil
        showFeedback = false
        isCorrect = false
        showResults = false
        questionResults = [:]
    }
    
    func selectAnswer(_ index: Int) {
        guard !showFeedback, let question = currentQuestion else { return }
        selectedAnswer = index
        let selectedOption = question.options[index]
        selectedAnswerText = selectedOption
        isCorrect = selectedOption == question.answer
        
        // Track the result for this question
        questionResults[currentQuestionIndex] = isCorrect
        
        if isCorrect {
            correctAnswers += 1
        }
        
        showFeedback = true
    }
    
    func nextQuestion() {
        selectedAnswer = nil
        selectedAnswerText = nil
        showFeedback = false
        isCorrect = false
        
        if currentQuestionIndex < testQuestions.count - 1 {
            currentQuestionIndex += 1
        } else {
            // Test complete
            showResults = true
        }
    }
    
    func getCorrectAnswerIndex() -> Int? {
        guard let question = currentQuestion else { return nil }
        return question.options.firstIndex(of: question.answer)
    }
    
    func stopTest() {
        // Clear test state but keep data loaded
        testQuestions = []
        currentQuestionIndex = 0
        correctAnswers = 0
        selectedAnswer = nil
        selectedAnswerText = nil
        showFeedback = false
        isCorrect = false
        showResults = false
        questionResults = [:]
    }
    
    func retakeTest(with questions: [PronounExercise]) {
        // Shuffle options for each question to ensure randomness
        testQuestions = questions.map { question in
            var shuffledOptions = question.options
            shuffledOptions.shuffle()
            return PronounExercise(
                id: question.id,
                sentence: question.sentence,
                basePronoun: question.basePronoun,
                options: shuffledOptions,
                answer: question.answer,
                rule: question.rule,
                level: question.level,
                translation: question.translation
            )
        }
        
        // Shuffle the test questions themselves for additional randomness
        testQuestions.shuffle()
        
        currentQuestionIndex = 0
        correctAnswers = 0
        selectedAnswer = nil
        selectedAnswerText = nil
        showFeedback = false
        isCorrect = false
        showResults = false
        questionResults = [:]
    }
}
