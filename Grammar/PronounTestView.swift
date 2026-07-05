//
//  PronounTestView.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

struct PronounTestView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PronounQuizViewModel
    @ObservedObject var resultsManager: TestResultsManager
    @StateObject private var audioManager = GrammarAudioManager()
    @State private var showWhyPopup = false
    @State private var showTranslation = false
    @State private var showScoreAlert = false
    @State private var showingResetConfirmation = false
    @State private var animatedOptionIndex: Int? = nil

    init(viewModel: PronounQuizViewModel, resultsManager: TestResultsManager) {
        self.viewModel = viewModel
        self.resultsManager = resultsManager
    }

    var body: some View {
        VStack(spacing: 0) {
            // Back and Reset on same row (Reset aligned vertically with Back)
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.body)
                    }
                    // Extra top offset needed only on the initial screen state.
                    .padding(.top, viewModel.testQuestions.isEmpty ? 60 : 0)
                    .foregroundColor(.appRed)
                }
                .padding(.top, 8)
                .padding(.leading, 4)
                Spacer()
                if !viewModel.testQuestions.isEmpty {
                    Button(action: { showingResetConfirmation = true }) {
                        Text("Reset")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            if viewModel.testQuestions.isEmpty {
                // Title (matches vocabulary initial screen style)
                HStack {
                    Spacer()
                    Text("Pronouns")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appRed)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 16)

                GrammarInitialScreenView(
                    resultsManager: resultsManager,
                    imageName: "pronouns",
                    imageUsesTemplate: true,
                    subtitle: "Master Swedish pronouns with 10 random questions per round",
                    grammarTestType: "Pronouns",
                    onStart: { viewModel.startNewTest() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    if let question = viewModel.currentQuestion, let pronounData = viewModel.pronounData {
                    // Main content
                    VStack(spacing: 0) {
                        // Header (title only; Reset is in top row with Back)
                        HStack {
                            Spacer()
                            Text("Pronouns")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.appRed)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
//                        .padding(.bottom, 20)
                        
                        // Horizontal divider above (same as ComparisonView)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 5)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, -100)
                            .overlay(alignment: .top) {
                                Text("\(viewModel.currentQuestionIndex + 1)/\(viewModel.testQuestions.count)")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                                    )
                                    .padding(.top, 8)
                            }
                        
                        // Content area - fixed height between dividers (same as ComparisonView)
                        VStack(spacing: 0) {
                            // Sentence area - fixed height 160 (animate when feedback shows)
                            VStack(spacing: 0) {
                                Spacer().frame(height: 50)
                                VStack(spacing: 0) {
                                    ZStack(alignment: .trailing) {
                                        HStack {
                                            Spacer()
                                            PronounSentenceView(
                                                sentence: question.sentence,
                                                answer: viewModel.selectedAnswerText,
                                                isCorrect: viewModel.isCorrect,
                                                showAnswer: viewModel.showFeedback,
                                                correctAnswer: question.answer
                                            )
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineSpacing(14)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 50)
                                        Button(action: {
                                            let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                                            if viewModel.showFeedback {
                                                audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: nil)
                                            } else {
                                                audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                audioManager.playAudio()
                                            }
                                        }) {
                                            Image("audio-headphone")
                                                .resizable()
                                                .renderingMode(.template)
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 28, height: 28)
                                                .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                                                .padding(8)
                                        }
                                        .disabled(!audioManager.isAudioReady || audioManager.isPlaying)
                                        .opacity((audioManager.isAudioReady && !audioManager.isPlaying) ? 1.0 : 0.4)
                                        .padding(.trailing, 20)
                                        .padding(.top, -60)
                                    }
                                    .padding(.top, 50)
                                    .padding(.bottom, 50)
                                }
                                Spacer().frame(height: 30)
                            }
                            .frame(height: 160)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.showFeedback)
                            
                            // Horizontal divider below (same as ComparisonView)
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 5)
                                .padding(.horizontal, 20)
                            
                            // Translation - below lower divider, fixed height 60 (same as ComparisonView)
                            VStack(spacing: 0) {
                                if !showTranslation && !viewModel.showFeedback {
                                    Button(action: {
                                        withAnimation { showTranslation = true }
                                    }) {
                                        Text("English here")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 24)
                                } else {
                                    translationText(question.translation ?? "", answer: question.answer)
                                        .font(.system(size: 16))
                                        .italic()
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: showTranslation)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 24)
                            .frame(height: 60)
                            .padding(.top, 1)
                            
                            Spacer().frame(height: 30)
                            
                            // Options (same as ComparisonView: spacing 16, horizontal 60, cycling pulse)
                            VStack(spacing: 16) {
                                ForEach(0..<question.options.count, id: \.self) { index in
                                    GrammarOptionButton(
                                        text: question.options[index],
                                        isSelected: viewModel.selectedAnswer == index,
                                        isCorrect: viewModel.showFeedback && question.options[index] == question.answer,
                                        isIncorrect: viewModel.showFeedback && viewModel.selectedAnswer == index && question.options[index] != question.answer,
                                        isDisabled: viewModel.showFeedback,
                                        isAnimating: animatedOptionIndex == index,
                                        action: {
                                            if !viewModel.showFeedback {
                                                withAnimation {
                                                    viewModel.selectAnswer(index)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 60)
                            
                            // Fixed spacing before feedback (same as ComparisonView)
                            Spacer()
                                .frame(height: 10)
                                .padding(.top, 20)
                            
                            Spacer()
                        }
                        .padding(.bottom, 80)
                    }
                } else if viewModel.exercises.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("No questions available")
                            .font(.headline)
                        Text("Please ensure pronounsData.json is included in the app bundle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ProgressView("Loading questions...")
                }
            }
            
                            // Feedback section - always present, positioned at bottom (same animation as Adjectives)
                if viewModel.currentQuestion != nil {
                    VStack(spacing: 12) {
                        // Feedback message - fixed height
                        ZStack {
                            if viewModel.showFeedback {
                                if viewModel.isCorrect {
                                    Text("Correct!")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.green)
                                } else {
                                    HStack(spacing: 8) {
                                        Text("Incorrect!")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.red)
                                        
                                        Button(action: {
                                            showWhyPopup = true
                                        }) {
                                            Text("Why?")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 70) // Fixed height (increased to accommodate padding)
                        .opacity(viewModel.showFeedback ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showFeedback)
                        
                        // Buttons - fixed height
                        ZStack {
                            if viewModel.showFeedback && viewModel.currentQuestionIndex == viewModel.testQuestions.count - 1 {
                                // Last question - show two buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation {
                                            viewModel.stopTest()
                                        }
                                    }) {
                                        Text("Close")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.gray)
                                            .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        withAnimation {
                                            viewModel.startNewTest()
                                        }
                                    }) {
                                        Text("New Test")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .cornerRadius(12)
                                    }
                                }
                                .onAppear {
                                    // Save result when buttons appear (last question answered)
                                    let result = TestResult(
                                        score: viewModel.currentScore,
                                        totalQuestions: viewModel.totalQuestions,
                                        testType: "Pronouns",
                                        verbQuestions: nil,
                                        pronounQuestions: viewModel.testQuestions,
                                        questionResults: viewModel.questionResults
                                    )
                                    resultsManager.saveResult(result)
                                    // Show score alert
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showScoreAlert = true
                                    }
                                }
                            } else {
                                // Not last question - show single button (always visible)
                                Button(action: {
                                    withAnimation {
                                        viewModel.nextQuestion()
                                    }
                                }) {
                                Text("Next")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(viewModel.showFeedback ? Color.blue : Color.gray)
                                    .cornerRadius(12)
                                }
                                .disabled(!viewModel.showFeedback)
                            }
                        }
                        .frame(height: 50) // Fixed height
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical)
            .navigationTitle("Pronouns Test")
            .navigationBarTitleDisplayMode(.inline)
            .clipped()
            .id("PronounTestView")
            .alert(isPresented: $showWhyPopup) {
                if let question = viewModel.currentQuestion {
                    let title = "The correct answer is: \(question.answer)"
                    let message = question.rule ?? ""
                    return Alert(
                        title: Text(title),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    return Alert(
                        title: Text("The correct answer is: "),
                        message: Text(""),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .alert("Are you sure?", isPresented: $showingResetConfirmation) {
                Button("No", role: .cancel) {}
                Button("Yes", role: .destructive) {
                    viewModel.stopTest()
                }
            } message: {
                Text("This will end the current test")
            }
            .alert("Test Complete!", isPresented: $showScoreAlert) {
                Button("OK") {
                    showScoreAlert = false
                }
            } message: {
                let score = viewModel.currentScore
                let total = viewModel.totalQuestions
                guard total > 0 else {
                    return Text("Your score: \(score)/\(total)")
                        .fontWeight(.bold)
                }
                let percentage = Int((Double(score) / Double(total)) * 100)
                return Text("Your score: \(score)/\(total) (\(percentage)%)")
                    .fontWeight(.bold)
            }
            .onChange(of: viewModel.currentQuestionIndex) {
                stopButtonAnimation()
                audioManager.cleanupAudio()
                showTranslation = false // Reset translation visibility for new question
                if let question = viewModel.currentQuestion {
                    let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                    startButtonAnimation()
                }
            }
            .onChange(of: viewModel.showFeedback) { _, newValue in
                if newValue {
                    stopButtonAnimation()
                } else {
                    startButtonAnimation()
                }
            }
            .onChange(of: viewModel.testQuestions.count) {
                // Generate audio when test starts (testQuestions becomes non-empty)
                if !viewModel.testQuestions.isEmpty {
                    audioManager.cleanupAudio()
                    if let question = viewModel.currentQuestion {
                        let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                        audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                    }
                }
            }
            .onAppear {
                if let question = viewModel.currentQuestion {
                    let sentenceWithAnswer = question.sentence.replacingOccurrences(of: "____", with: question.answer)
                    audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: question.answer)
                    startButtonAnimation()
                }
            }
            .onDisappear {
                stopButtonAnimation()
                audioManager.cleanupAudio()
            }
            .sheet(isPresented: $viewModel.showResults) {
                TestResultsView(
                    score: viewModel.currentScore,
                    totalQuestions: viewModel.totalQuestions,
                    onNewTest: {
                        viewModel.startNewTest()
                    },
                    onClose: {
                        viewModel.startNewTest() // Reset when closing
                    },
                    onSave: {
                        let result = TestResult(score: viewModel.currentScore, totalQuestions: viewModel.totalQuestions, testType: "Pronouns")
                        resultsManager.saveResult(result)
                    }
                )
            }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func startButtonAnimation() {
        guard let question = viewModel.currentQuestion, !question.options.isEmpty, !viewModel.showFeedback else {
            animatedOptionIndex = nil
            return
        }
        let count = question.options.count
        func animateButton(at index: Int) {
            guard viewModel.currentQuestion != nil, !viewModel.showFeedback else {
                animatedOptionIndex = nil
                return
            }
            withAnimation(.easeInOut(duration: 0.1)) {
                animatedOptionIndex = index
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatedOptionIndex = nil
                }
                let nextIndex = (index + 1) % count
                if nextIndex == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                        animateButton(at: 0)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        animateButton(at: nextIndex)
                    }
                }
            }
        }
        animateButton(at: 0)
    }

    private func stopButtonAnimation() {
        animatedOptionIndex = nil
    }

    @ViewBuilder
    private func translationText(_ translation: String, answer: String) -> some View {
        let pronounMap: [String: String] = [
            "mig": "me", "dig": "you", "sig": "itself", "oss": "us", "er": "you",
            "min": "my", "din": "your", "sin": "his", "vår": "our",
            "mitt": "my", "ditt": "your", "sitt": "his", "vårt": "our", "ert": "your",
            "mina": "my", "dina": "your", "sina": "his", "våra": "our", "era": "your",
            "henne": "her", "honom": "him", "dem": "them", "hennes": "hers", "hans": "his",
            "varandra": "each other", "dess": "its", "hon": "she", "han": "he", "de": "they",
            "du": "you", "jag": "i", "vi": "we", "ni": "you"
        ]
        
        let englishWord = pronounMap[answer.lowercased()] ?? answer
        
        // Split translation into words, preserving punctuation
        let words = translation.split(separator: " ", omittingEmptySubsequences: true)
        
        var result = Text("")
        var isFirst = true
        
        for word in words {
            let wordString = String(word)
            let cleanWord = wordString.trimmingCharacters(in: .punctuationCharacters).lowercased()
            
            if !isFirst {
                result = result + Text(" ")
            }
            
            if cleanWord == englishWord.lowercased() || cleanWord.contains(englishWord.lowercased()) || englishWord.lowercased().contains(cleanWord) {
                result = result + Text(wordString)
                    .fontWeight(.bold)
            } else {
                result = result + Text(wordString)
            }
            isFirst = false
        }
        
        return result
    }
    
}

struct PronounSentenceView: View {
    let sentence: String
    let answer: String?
    let isCorrect: Bool
    let showAnswer: Bool
    let correctAnswer: String?

    var body: some View {
        // Same design as Adjectives: bold sentence, missing word (____) or selected/correct answer in blue
        GrammarSentenceStyle.sentenceWithBlank(
            sentence,
            blankMarker: "____",
            displayText: showAnswer ? correctAnswer : answer
        )
        .lineSpacing(14)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    PronounTestView(viewModel: PronounQuizViewModel(), resultsManager: TestResultsManager())
}


