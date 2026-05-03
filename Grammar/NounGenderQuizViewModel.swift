//
//  NounGenderQuizViewModel.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NounGenderQuizViewModel: ObservableObject {
    @Published var nounGenderData: NounGenderData?
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswer: Int? = nil
    @Published var selectedAnswerText: String? = nil
    @Published var showFeedback: Bool = false
    @Published var isCorrect: Bool = false
    @Published var showResults: Bool = false
    @Published var testQuestions: [NounGenderExercise] = []
    @Published var correctAnswers: Int = 0
    @Published var questionResults: [Int: Bool] = [:] // Track which questions were answered correctly
    
    private let questionsPerTest = 10
    
    var currentQuestion: NounGenderExercise? {
        guard currentQuestionIndex < testQuestions.count else { return nil }
        return testQuestions[currentQuestionIndex]
    }
    
    var nouns: [NounGenderExercise] {
        nounGenderData?.nouns ?? []
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
        let url = Bundle.main.url(forResource: "nounGenderData", withExtension: "json", subdirectory: "Grammar/Data")
            ?? Bundle.main.url(forResource: "nounGenderData", withExtension: "json")
        guard let url = url else {
            print("Error: Could not find nounGenderData.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(NounGenderData.self, from: data)
            nounGenderData = decoded
        } catch {
            print("Error loading noun gender data: \(error.localizedDescription)")
        }
    }
    
    func startNewTest() {
        guard let allNouns = nounGenderData?.nouns, !allNouns.isEmpty else {
            return
        }
        
        // Separate nouns by gender
        let enNouns = allNouns.filter { $0.gender == "en" }
        let ettNouns = allNouns.filter { $0.gender == "ett" }
        
        // Calculate how many of each type to select (80% en, 20% ett)
        let enCount = Int(round(Double(questionsPerTest) * 0.8))
        let ettCount = questionsPerTest - enCount
        
        // Shuffle and select from each group
        var selectedQuestions: [NounGenderExercise] = []
        
        // Select "en" words (80%)
        if enCount > 0 && !enNouns.isEmpty {
            var shuffledEn = enNouns.shuffled()
            let selectedEn = Array(shuffledEn.prefix(min(enCount, enNouns.count)))
            selectedQuestions.append(contentsOf: selectedEn)
        }
        
        // Select "ett" words (20%)
        if ettCount > 0 && !ettNouns.isEmpty {
            var shuffledEtt = ettNouns.shuffled()
            let selectedEtt = Array(shuffledEtt.prefix(min(ettCount, ettNouns.count)))
            selectedQuestions.append(contentsOf: selectedEtt)
        }
        
        // If we don't have enough questions, fill the rest randomly
        if selectedQuestions.count < questionsPerTest {
            let remaining = questionsPerTest - selectedQuestions.count
            let allNounsShuffled = allNouns.shuffled()
            let additional = allNounsShuffled.filter { noun in
                !selectedQuestions.contains { $0.id == noun.id }
            }.prefix(remaining)
            selectedQuestions.append(contentsOf: additional)
        }
        
        // Shuffle options for each question to ensure complete randomness
        testQuestions = selectedQuestions.map { noun in
            var shuffledOptions = noun.options
            shuffledOptions.shuffle()
            // Create a new exercise with shuffled options
            return NounGenderExercise(
                id: noun.id,
                swedish: noun.swedish,
                english: noun.english,
                gender: noun.gender,
                example: noun.example
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
    
    func retakeTest(with questions: [NounGenderExercise]) {
        // Shuffle options for each question to ensure randomness
        testQuestions = questions.map { noun in
            var shuffledOptions = noun.options
            shuffledOptions.shuffle()
            return NounGenderExercise(
                id: noun.id,
                swedish: noun.swedish,
                english: noun.english,
                gender: noun.gender,
                example: noun.example
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
