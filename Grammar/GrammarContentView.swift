//
//  GrammarContentView.swift
//  SWGrammar (renamed from ContentView.swift to avoid duplicate build output)
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

struct GrammarContentView: View {
    @StateObject private var viewModel = VerbQuizViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if let question = viewModel.currentQuestion, let verbData = viewModel.verbData {
                    // Topic and Instruction
                    VStack(spacing: 8) {
                        Text(verbData.topic)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(verbData.instruction)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Question number
                    HStack {
                        Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.exercises.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Level \(question.level)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Sentence
                    VStack(spacing: 15) {
                        Text(question.sentence)
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Options
                    VStack(spacing: 15) {
                        ForEach(0..<question.options.count, id: \.self) { index in
                            Button(action: {
                                withAnimation {
                                    viewModel.selectAnswer(index)
                                }
                            }) {
                                HStack {
                                    Text(question.options[index])
                                        .font(.headline)
                                        .foregroundColor(buttonTextColor(for: index))
                                    Spacer()
                                    if viewModel.showFeedback {
                                        Image(systemName: iconName(for: index))
                                            .foregroundColor(buttonTextColor(for: index))
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(buttonBackgroundColor(for: index))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(buttonBorderColor(for: index), lineWidth: 2)
                                )
                            }
                            .disabled(viewModel.showFeedback)
                        }
                    }
                    .padding(.horizontal)

                    // Feedback
                    if viewModel.showFeedback {
                        VStack(spacing: 12) {
                            if viewModel.isCorrect {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Correct!")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            } else {
                                VStack(spacing: 10) {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                        Text("Incorrect")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                    }

                                    Text("Correct answer: \(question.answer)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Text(question.rule)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }

                            Button(action: {
                                withAnimation {
                                    viewModel.nextQuestion()
                                }
                            }) {
                                Text("Next Question")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()
                } else if viewModel.exercises.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("No questions available")
                            .font(.headline)
                        Text("Please ensure verbData.json is included in the app bundle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ProgressView("Loading questions...")
                }
            }
            .padding(.vertical)
            .navigationTitle("Swedish Grammar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func buttonTextColor(for index: Int) -> Color {
        guard let question = viewModel.currentQuestion else { return .primary }

        if !viewModel.showFeedback {
            return .primary
        }

        if viewModel.isCorrect && index == viewModel.selectedAnswer {
            return .white
        } else if !viewModel.isCorrect {
            if index == viewModel.selectedAnswer {
                return .white
            } else if question.options[index] == question.answer {
                return .white
            }
        }
        return .primary
    }

    private func buttonBackgroundColor(for index: Int) -> Color {
        guard let question = viewModel.currentQuestion else { return Color(.systemGray6) }

        if !viewModel.showFeedback {
            return Color(.systemGray6)
        }

        if viewModel.isCorrect && index == viewModel.selectedAnswer {
            return .green
        } else if !viewModel.isCorrect {
            if index == viewModel.selectedAnswer {
                return .red
            } else if question.options[index] == question.answer {
                return .green
            }
        }
        return Color(.systemGray6)
    }

    private func buttonBorderColor(for index: Int) -> Color {
        guard let question = viewModel.currentQuestion else { return .clear }

        if !viewModel.showFeedback {
            return .clear
        }

        if viewModel.isCorrect && index == viewModel.selectedAnswer {
            return .green
        } else if !viewModel.isCorrect {
            if index == viewModel.selectedAnswer {
                return .red
            } else if question.options[index] == question.answer {
                return .green
            }
        }
        return .clear
    }

    private func iconName(for index: Int) -> String {
        guard let question = viewModel.currentQuestion else { return "" }

        if viewModel.isCorrect && index == viewModel.selectedAnswer {
            return "checkmark.circle.fill"
        } else if !viewModel.isCorrect {
            if index == viewModel.selectedAnswer {
                return "xmark.circle.fill"
            } else if question.options[index] == question.answer {
                return "checkmark.circle.fill"
            }
        }
        return ""
    }
}

#Preview {
    GrammarContentView()
}
