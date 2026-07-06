//
//  TestResultsView.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

struct TestResultsView: View {
    let score: Int
    let totalQuestions: Int
    let onNewTest: () -> Void
    let onClose: () -> Void
    let onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    private var percentage: Double {
        Double(score) / Double(totalQuestions) * 100.0
    }
    
    private var resultColor: Color {
        if percentage >= 80 {
            return .green
        } else if percentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var resultEmoji: String {
        if percentage >= 90 {
            return "🌟"
        } else if percentage >= 80 {
            return "👍"
        } else if percentage >= 60 {
            return "😊"
        } else {
            return "📚"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Result emoji
                Text(resultEmoji)
                    .font(.system(size: 80))
                
                // Score
                VStack(spacing: 8) {
                    Text("\(score) / \(totalQuestions)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(resultColor)
                    
                    Text("\(Int(percentage))%")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Message
                Text(resultMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        onNewTest()
                        dismiss()
                    }) {
                        Text("Start New Test")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appRed)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        onClose()
                        dismiss()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.appRed)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Test Results")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Save result once when the results view appears
            onSave()
        }
    }
    
    private var resultMessage: String {
        if percentage >= 90 {
            return "Excellent! You're a Swedish grammar master! 🌟"
        } else if percentage >= 80 {
            return "Great job! You're doing really well! 👍"
        } else if percentage >= 60 {
            return "Good effort! Keep practicing! 😊"
        } else {
            return "Keep studying! You'll improve! 📚"
        }
    }
}

#Preview {
    TestResultsView(
        score: 7,
        totalQuestions: 10,
        onNewTest: {},
        onClose: {},
        onSave: {}
    )
}
