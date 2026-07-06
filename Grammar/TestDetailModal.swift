//
//  TestDetailModal.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

struct TestDetailModal: View {
    let result: TestResult
    @Binding var isPresented: Bool
    @ObservedObject var verbQuizViewModel: VerbQuizViewModel
    @ObservedObject var pronounQuizViewModel: PronounQuizViewModel
    @ObservedObject var nounGenderQuizViewModel: NounGenderQuizViewModel
    @ObservedObject var reflexiveQuizViewModel: ReflexiveQuizViewModel
    @ObservedObject var resultsManager: TestResultsManager
    @State private var navigateToTest = false
    @State private var targetTab: Int = 2
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        return formatter
    }
    
    private var canRetake: Bool {
        if result.testType == "Verbs" {
            return result.verbQuestions != nil && !result.verbQuestions!.isEmpty
        } else if result.testType == "Pronouns" {
            return result.pronounQuestions != nil && !result.pronounQuestions!.isEmpty
        } else if result.testType == "Noun Gender" {
            return result.nounGenderQuestions != nil && !result.nounGenderQuestions!.isEmpty
        } else if result.testType == "Reflexiva pronomen" {
            return result.reflexiveQuestions != nil && !result.reflexiveQuestions!.isEmpty
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Test summary
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(result.testType)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(dateFormatter.string(from: result.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(result.percentage))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(result.percentage))
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
                
                // Questions list
                ScrollView {
                    VStack(spacing: 12) {
                        if let verbQuestions = result.verbQuestions, !verbQuestions.isEmpty {
                            ForEach(Array(verbQuestions.enumerated()), id: \.element.id) { index, question in
                                QuestionRow(
                                    index: index + 1,
                                    sentence: question.sentence,
                                    answer: question.answer,
                                    translation: question.translation,
                                    isCorrect: result.questionResults[index] ?? false
                                )
                            }
                        } else if let pronounQuestions = result.pronounQuestions, !pronounQuestions.isEmpty {
                            ForEach(Array(pronounQuestions.enumerated()), id: \.element.id) { index, question in
                                QuestionRow(
                                    index: index + 1,
                                    sentence: question.sentence,
                                    answer: question.answer,
                                    translation: question.translation,
                                    isCorrect: result.questionResults[index] ?? false
                                )
                            }
                        } else if let nounGenderQuestions = result.nounGenderQuestions, !nounGenderQuestions.isEmpty {
                            ForEach(Array(nounGenderQuestions.enumerated()), id: \.element.id) { index, question in
                                QuestionRow(
                                    index: index + 1,
                                    sentence: question.sentence,
                                    answer: question.answer,
                                    translation: question.translation,
                                    isCorrect: result.questionResults[index] ?? false
                                )
                            }
                        } else if let reflexiveQuestions = result.reflexiveQuestions, !reflexiveQuestions.isEmpty {
                            ForEach(Array(reflexiveQuestions.enumerated()), id: \.element.id) { index, question in
                                QuestionRow(
                                    index: index + 1,
                                    sentence: question.sentence,
                                    answer: question.answer,
                                    translation: question.translation,
                                    isCorrect: result.questionResults[index] ?? false
                                )
                            }
                        } else {
                            Text("Question details not available for this test")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Test Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake") {
                        retakeTest()
                    }
                    .disabled(!canRetake)
                    .foregroundColor(.appRed)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.appRed)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func retakeTest() {
        if result.testType == "Verbs", let verbQuestions = result.verbQuestions {
            // Load the stored questions into the verb ViewModel
            verbQuizViewModel.retakeTest(with: verbQuestions)
            targetTab = 2 // Navigate to Verbs tab
        } else if result.testType == "Pronouns", let pronounQuestions = result.pronounQuestions {
            // Load the stored questions into the pronoun ViewModel
            pronounQuizViewModel.retakeTest(with: pronounQuestions)
            targetTab = 1 // Navigate to Pronouns tab
        } else if result.testType == "Noun Gender", let nounGenderQuestions = result.nounGenderQuestions {
            nounGenderQuizViewModel.retakeTest(with: nounGenderQuestions)
            targetTab = 4 // Navigate to Noun Gender tab
        } else if result.testType == "Reflexiva pronomen", let reflexiveQuestions = result.reflexiveQuestions {
            reflexiveQuizViewModel.retakeTest(with: reflexiveQuestions)
            targetTab = 3 // Navigate to Reflexiva pronomen tab
        }
        
        isPresented = false
        
        // Post notification to navigate to the appropriate tab
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToTest"), object: nil, userInfo: ["tab": targetTab])
        }
    }
    
    private func scoreColor(_ percentage: Double) -> Color {
        if percentage >= 80 {
            return .green
        } else if percentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }
}

struct QuestionRow: View {
    let index: Int
    let sentence: String
    let answer: String
    let translation: String?
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("\(index).")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Split sentence and make answer bold
                Group {
                    let parts = sentence.components(separatedBy: "____")
                    if parts.count == 2 {
                        let beforePart = parts[0]
                        let afterPart = parts[1]
                        (Text(beforePart)
                            .fontWeight(.medium) +
                         Text(answer)
                            .fontWeight(.bold) +
                         Text(afterPart)
                            .fontWeight(.medium))
                            .font(.body)
                    } else {
                        Text(sentence.replacingOccurrences(of: "____", with: answer))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
            
            if let translation = translation, !translation.isEmpty {
                Text(translation)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
        .cornerRadius(10)
    }
}

#Preview {
    TestDetailModal(
        result: TestResult(score: 8, totalQuestions: 10, testType: "Verbs"),
        isPresented: .constant(true),
        verbQuizViewModel: VerbQuizViewModel(),
        pronounQuizViewModel: PronounQuizViewModel(),
        nounGenderQuizViewModel: NounGenderQuizViewModel(),
        reflexiveQuizViewModel: ReflexiveQuizViewModel(),
        resultsManager: TestResultsManager()
    )
}
