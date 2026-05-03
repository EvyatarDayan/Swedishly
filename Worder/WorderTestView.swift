//
//  WorderTestView.swift
//  Swedishly
//

import SwiftUI
import UIKit

// MARK: - Test View (10-question test using WorderPracticeView)
struct WorderTestView: View {
    @State private var exampleIds: [Int] = []
    @State private var summaryItem: TestSummary? = nil
    
    private struct TestSummary: Identifiable {
        let id = UUID()
        let questions: Int
        let correct: Int
        let results: [WorderQuestionResult]
    }
    
    init() {
        let ids = WorderPracticeHistoryManager.shared.generateSessionExampleIDs(total: 10)
        _exampleIds = State(initialValue: ids)
    }
    
    private func motivationalMessage(for percentage: Int) -> String {
        switch percentage {
        case 0...25: return "Keep practicing, you can do it!"
        case 26...50: return "You're making progress, keep going!"
        case 51...75: return "Great job! You're doing well!"
        case 76...100: return "Excellent work! You're mastering this!"
        default: return "Keep practicing!"
        }
    }
    
    var body: some View {
        ZStack {
            WorderPracticeView(
                initialExampleIds: exampleIds,
                onSessionComplete: { questions, correct, results in
                    print("[WorderTestView] onSessionComplete -> questions:\(questions) correct:\(correct) results:\(results.count)")
                    WorderPracticeHistoryManager.shared.addSession(
                        questions: questions,
                        correct: correct,
                        exampleIDs: exampleIds,
                        questionResults: results,
                        sessionType: .test
                    )
                    DispatchQueue.main.async {
                        let s = TestSummary(questions: questions, correct: correct, results: results)
                        summaryItem = s
                        NotificationCenter.default.post(name: .worderResetSession, object: nil)
                    }
                },
                customTitle: "Test",
                sessionLimit: 10,
                sessionType: .test,
                historyInitialFilter: .test
            )
            .sheet(item: $summaryItem, onDismiss: {
                let all = WordOrderDataManager.shared.getAllExamples()
                exampleIds = Array(all.shuffled().prefix(10).map { $0.id })
            }) { item in
                WorderSummaryModal(
                    questions: item.questions,
                    correct: item.correct,
                    wrong: max(0, item.questions - item.correct),
                    successPercentage: item.questions > 0 ? Int((Double(item.correct) / Double(item.questions)) * 100) : 0,
                    motivationalMessage: motivationalMessage(for: item.questions > 0 ? Int((Double(item.correct) / Double(item.questions)) * 100) : 0)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
