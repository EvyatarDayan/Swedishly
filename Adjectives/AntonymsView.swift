//
//  AntonymsView.swift
//  Swedisher
//
//  Created by EVYATAR DAYAN on 2026-01-30.
//

import SwiftUI
import UIKit

// MARK: - Data Models
struct AntonymExample: Codable, Identifiable {
    let id: Int
    let group: String
    let sentence: String
    let answer: String
    let englishAnswer: String
    let options: [String]
    let translation: String
}

// MARK: - Data Manager
class AntonymDataManager {
    static let shared = AntonymDataManager()
    
    private var examples: [AntonymExample] = []
    
    init() {
        loadData()
    }
    
    private func loadData() {
        var url = Bundle.main.url(forResource: "dataAntonyms", withExtension: "json", subdirectory: "Adjectives/Data")
        if url == nil {
            url = Bundle.main.url(forResource: "dataAntonyms", withExtension: "json")
        }
        guard let url = url else {
            print("❌ Could not find dataAntonyms.json file")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            examples = try decoder.decode([AntonymExample].self, from: data)
            print("✅ Loaded \(examples.count) examples from dataAntonyms.json")
        } catch {
            print("❌ Error loading dataAntonyms.json: \(error)")
        }
    }
    
    func getAllExamples() -> [AntonymExample] {
        return examples
    }
    
    func getRandomExample() -> AntonymExample? {
        return examples.randomElement()
    }
}

// MARK: - Antonyms View
struct AntonymsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var audioManager = AdjectivesAudioManager()
    @StateObject private var practiceHistoryManager = AdjectivesPracticeHistoryManager.shared
    @State private var currentExample: AntonymExample?
    @State private var options: [String] = []
    @State private var correctAnswer: String = ""
    @State private var selectedAnswer: String?
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var questionCount: Int = 0
    @State private var showTranslation2: Bool = false
    @State private var animatedOptionIndex: Int? = nil
    @State private var visibleLetterCount: Int = 0
    @State private var showUpIcon: Bool = false
    
    // Session statistics
    @State private var sessionQuestions: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var sessionWrong: Int = 0
    @State private var sessionQuestionDetails: [AdjectivesPracticeQuestionSummary] = []
    @State private var showingSessionSummary: Bool = false
    @State private var showingDoneConfirmation: Bool = false
    @State private var shownQuestionIds: Set<Int> = [] // Track shown question IDs in current session
    @State private var buttonAnimationTimer: Timer?
    
    // Practice progress key
    private let practiceProgressKey = "antonymPracticeProgress"
    
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
                    .foregroundColor(.appRed)
                }
                .padding(.top, 8)
                .padding(.leading, 4)
                Spacer()
                if currentExample != nil {
                    Button(action: { showingDoneConfirmation = true }) {
                        Text("Reset")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            // Header (title only)
            HStack {
                Spacer()
                Text("Antonyms")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.appRed)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            
            if let example = currentExample {
                VStack(spacing: 0) {
                    // Horizontal divider above
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, -100)
                        .overlay(alignment: .top) {
                            // Progress indicator overlay
                            if questionCount > 0 {
                                let currentQuestion = (questionCount % 20 == 0 && questionCount > 0) ? 20 : (questionCount % 20)
                                Text("\(currentQuestion)/20")
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
                        }
                    
                    // Content area - fixed height between dividers
                    VStack(spacing: 0) {
                        // Fixed height container for sentence area (between two dividers)
                        VStack(spacing: 0) {
                            // Top padding - fixed
                            Spacer()
                                .frame(height: 50)
                            
                            // Sentence display
                            VStack(spacing: 0) {
                                ZStack(alignment: .trailing) {
                                    HStack {
                                        Spacer()
                                        HStack(alignment: .top, spacing: 8) {
                                            sentenceWithBlank(example.sentence, selectedAnswer: showFeedback ? correctAnswer : selectedAnswer)
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineSpacing(14)
                                        }
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 50)
                                    
                                    // Audio button - small icon on the right inside the frame
                                    Button(action: {
                                        let sentenceWithAnswer = example.sentence.replacingOccurrences(of: "______", with: example.answer)
                                        if showFeedback {
                                            // After answering, play full sentence without beep
                                            audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: nil)
                                        } else {
                                            // Before answering, play with beep
                                            audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: example.answer)
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
                                .onAppear {
                                    animateSentenceAppearance()
                                }
                                .onChange(of: currentExample?.sentence) { oldValue, newValue in
                                    if newValue != nil {
                                        animateSentenceAppearance()
                                    }
                                }
                            }
                            
                            // Bottom padding - fixed
                            Spacer()
                                .frame(height: 30)
                        }
                        .frame(height: 160) // Fixed height: 50 (top) + 80 (sentence padding) + 30 (bottom) = 160
                        
                        // Horizontal divider below - fixed
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 5)
                            .padding(.horizontal, 20)
                        
                        // Translation 2 - below lower divider (fixed height)
                        VStack(spacing: 0) {
                            Group {
                                if let example = currentExample {
                                    if !showTranslation2 {
                                        Button(action: {
                                            withAnimation {
                                                showTranslation2 = true
                                            }
                                        }) {
                                            Text("English here")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                    } else {
                                        // Show translation - blur answer word only if not answered yet
                                        if showFeedback {
                                            // After answering, show full translation without blur
                                            Text(example.translation)
                                                .font(.system(size: 16))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .italic()
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.horizontal, 20)
                                                .transition(.opacity)
                                        } else {
                                            // Before answering, blur the answer word
                                            translationWithBlurredAnswer(example.translation, englishAnswer: example.englishAnswer)
                                                .font(.system(size: 16))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .italic()
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.horizontal, 20)
                                                .transition(.opacity)
                                        }
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: showTranslation2)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 24) // Minimum height for button
                        }
                        .frame(height: 60) // Fixed height for translation area
                        .padding(.top, 1)
                        
                        Spacer()
                            .frame(height: 30)
                        
                        // Options
                        VStack(spacing: 16) {
                            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                                AdjectivesOptionButton(
                                    text: option,
                                    isSelected: selectedAnswer == option,
                                    isCorrect: showFeedback && option == correctAnswer,
                                    isIncorrect: showFeedback && selectedAnswer == option && option != correctAnswer,
                                    isDisabled: showFeedback,
                                    isAnimating: animatedOptionIndex == index,
                                    action: {
                                        if !showFeedback {
                                            selectedAnswer = option
                                            checkAnswer(selected: option)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 60)
                        
                        // Fixed spacing before feedback
                        Spacer()
                            .frame(height: 10)
                            .padding(.top, 20)
                        
                        // Feedback labels
                        VStack(spacing: 12) {
                            if showFeedback {
                                Text(isCorrect ? "Correct!" : "Incorrect!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(isCorrect ? .green : .red)
                                    .padding(.top, 12)
                            } else {
                                HStack(spacing: 8) {
                                    if showUpIcon {
                                        Image("up")
                                            .resizable()
                                            .renderingMode(.template)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.blue)
                                            .transition(.opacity)
                                    }
                                    Text("Choose an answer")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .padding(.top, 12)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: showFeedback)
                        
                        Spacer()
                    }
                    
                    // Next button
                    Button(action: {
                        nextWord()
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background((selectedAnswer != nil && sessionQuestions < 20) ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(selectedAnswer == nil || sessionQuestions >= 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            } else {
                // Default/empty state - initial page
                VStack(spacing: 15) {
                    Spacer()
                    
                    Image("practice2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                        Text("Learn to pair opposites, find the words to describe constracting and objects")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 15)
                    
                    Button(action: {
                        loadRandomWord()
                    }) {
                        Text("Start new practice")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        NotificationCenter.default.post(name: .openHistoryWithAdjectivesFilter, object: nil)
                    }) {
                        Text("Previous practices")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 12)

                    let last = practiceHistoryManager.historyItems
                        .filter({ $0.practiceType == .antonym })
                        .max(by: { $0.dateTaken < $1.dateTaken })

                    Group {
                        if let last {
                            SessionSuccessRingChart(
                                correct: last.correct,
                                questions: last.questions,
                                dateTaken: last.dateTaken,
                                successPercentage: last.successPercentage,
                                titlePrefix: "Your last practice"
                            )
                            .id("\(last.dateTaken.timeIntervalSince1970)-\(last.questions)-antonym")
                        } else {
                            SessionSuccessRingChart(
                                correct: 0,
                                questions: 0,
                                dateTaken: Date(),
                                successPercentage: 0,
                                titlePrefix: "Your last practice",
                                titleOverride: "No practice information yet"
                            )
                            .id("adjectives-no-session-antonym")
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    Spacer()
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingSessionSummary, onDismiss: {
            resetToDefaultScreen()
        }) {
            AdjectivesPracticeSummaryModal(
                questions: sessionQuestions,
                correct: sessionCorrect,
                wrong: sessionWrong,
                successPercentage: successPercentage,
                motivationalMessage: motivationalMessage
            )
        }
        .alert("Are you sure?", isPresented: $showingDoneConfirmation) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                resetToDefaultScreen()
            }
        } message: {
            Text("This will reset the current practice")
        }
        .onAppear {
            // Load practice progress when view appears (only if we don't already have a word)
            if currentExample == nil {
                loadPracticeProgress()
            }
            if let example = currentExample {
                let sentenceWithAnswer = example.sentence.replacingOccurrences(of: "______", with: example.answer)
                audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: example.answer)
            }
            startButtonAnimation()
        }
        .onDisappear {
            stopButtonAnimation()
            audioManager.cleanupAudio()
            // Save progress when view disappears
            savePracticeProgress()
        }
        .onChange(of: currentExample?.id) { oldValue, newValue in
            stopButtonAnimation()
            if newValue != nil {
                startButtonAnimation()
            }
            // Save progress when example changes
            if newValue != nil {
                savePracticeProgress()
            }
        }
        .onChange(of: showFeedback) { oldValue, newValue in
            if newValue {
                stopButtonAnimation()
            } else {
                startButtonAnimation()
            }
            // Save progress when feedback changes
            if newValue {
                savePracticeProgress()
            }
        }
        .onChange(of: selectedAnswer) { oldValue, newValue in
            // Save progress when answer is selected
            if newValue != nil {
                savePracticeProgress()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Helper Functions
    private func loadRandomWord() {
        if questionCount == 0 || questionCount % 20 == 0 {
            sessionQuestions = 0
            sessionCorrect = 0
            sessionWrong = 0
            shownQuestionIds = [] // Reset shown questions for new session
        }
        
        questionCount += 1
        
        // Get all examples and filter out already shown ones
        let allExamples = AntonymDataManager.shared.getAllExamples()
        let availableExamples = allExamples.filter { !shownQuestionIds.contains($0.id) }
        
        // If we've shown all questions, reset the shown list
        guard let example = availableExamples.randomElement() ?? allExamples.randomElement() else {
            print("❌ No examples available")
            return
        }
        
        // Mark this question as shown
        shownQuestionIds.insert(example.id)
        
        setupExample(example)
    }
    
    private func setupExample(_ example: AntonymExample) {
        currentExample = example
        correctAnswer = example.answer
        
        // Remove duplicates from options while preserving order, then shuffle
        var uniqueOptions: [String] = []
        var seenOptions: Set<String> = []
        for option in example.options {
            if !seenOptions.contains(option) {
                uniqueOptions.append(option)
                seenOptions.insert(option)
            }
        }
        options = uniqueOptions.shuffled()
        
        // Reset state
        selectedAnswer = nil
        showFeedback = false
        isCorrect = false
        showTranslation2 = false
        animatedOptionIndex = nil
        
        // Generate audio for the new example
        let sentenceWithAnswer = example.sentence.replacingOccurrences(of: "______", with: example.answer)
        audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: example.answer)
    }
    
    private func startButtonAnimation() {
        stopButtonAnimation() // Stop any existing timer
        
        // Only animate if we have options and no feedback is shown
        guard !options.isEmpty && !showFeedback else { return }
        
        // Function to animate a single button
        func animateButton(at index: Int) {
            // Only continue if we still have options and no feedback
            guard !options.isEmpty && !showFeedback else {
                stopButtonAnimation()
                return
            }
            
            // Animate the current button
            withAnimation(.easeInOut(duration: 0.1)) {
                animatedOptionIndex = index
            }
            
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatedOptionIndex = nil
                }
                
                // Move to next button
                let nextIndex = (index + 1) % options.count
                
                // If we've completed a full cycle, wait 10 seconds before next cycle
                if nextIndex == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                        animateButton(at: 0)
                    }
                } else {
                    // Continue to next button immediately
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                        animateButton(at: nextIndex)
                    }
                }
            }
        }
        
        // Start animating immediately
        animateButton(at: 0)
    }
    
    private func stopButtonAnimation() {
        buttonAnimationTimer?.invalidate()
        buttonAnimationTimer = nil
        animatedOptionIndex = nil
    }
    
    private func checkAnswer(selected: String) {
        isCorrect = selected.lowercased() == correctAnswer.lowercased()
        showFeedback = true
        showTranslation2 = true // Automatically show translation after answering
        
        sessionQuestions += 1
        if isCorrect {
            sessionCorrect += 1
        } else {
            sessionWrong += 1
        }
        
        if let example = currentExample {
            let summary = AdjectivesPracticeQuestionSummary(
                sentence: example.sentence,
                answer: example.answer,
                englishAnswer: example.englishAnswer,
                isCorrect: isCorrect
            )
            sessionQuestionDetails.append(summary)
        }
        
        if sessionQuestions >= 20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showingSessionSummary = true
            }
        }
    }
    
    private var successPercentage: Int {
        guard sessionQuestions > 0 else { return 0 }
        return Int((Double(sessionCorrect) / Double(sessionQuestions)) * 100)
    }
    
    private var motivationalMessage: String {
        let percentage = successPercentage
        switch percentage {
        case 0...25:
            return "Keep practicing, you can do it!"
        case 26...50:
            return "You're making progress, keep going!"
        case 51...75:
            return "Great job! You're doing well!"
        case 76...100:
            return "Excellent work! You're mastering this!"
        default:
            return "Keep practicing!"
        }
    }
    
    private func resetToDefaultScreen() {
        // Save to history if session is completed (exactly 20 questions)
        if sessionQuestions == 20 {
            let historyItem = AdjectivesPracticeHistoryItem(
                dateTaken: Date(),
                questions: sessionQuestions,
                correct: sessionCorrect,
                wrong: sessionWrong,
                successPercentage: successPercentage,
                practiceType: .antonym,
                questionsDetail: sessionQuestionDetails
            )
            practiceHistoryManager.addHistoryItem(historyItem)
        }
        
        // Clear progress when resetting
        clearPracticeProgress()
        
        currentExample = nil
        selectedAnswer = nil
        showFeedback = false
        isCorrect = false
        showTranslation2 = false
        questionCount = 0
        options = []
        correctAnswer = ""
        animatedOptionIndex = nil
        visibleLetterCount = 0
        showUpIcon = false
        sessionQuestions = 0
        sessionCorrect = 0
        sessionWrong = 0
        shownQuestionIds = [] // Clear shown questions
        sessionQuestionDetails = []
    }
    
    private func nextWord() {
        if sessionQuestions >= 20 {
            return
        }
        loadRandomWord()
    }
    
    private func animateSentenceAppearance() {
        visibleLetterCount = 0
        showUpIcon = false
        
        guard let example = currentExample else { return }
        let totalLetters = example.sentence.count
        
        for index in 0..<totalLetters {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                withAnimation(.easeOut(duration: 0.15)) {
                    visibleLetterCount = index + 1
                }
            }
        }
        
        let totalAnimationTime = Double(totalLetters) * 0.02 + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationTime) {
            withAnimation(.easeIn(duration: 0.3)) {
                showUpIcon = true
            }
        }
    }
    
    @ViewBuilder
    private func sentenceWithBlank(_ sentence: String, selectedAnswer: String?) -> some View {
        let parts = sentence.components(separatedBy: "______")
        
        if parts.count == 2 {
            // Build the full text string - use selectedAnswer if provided, otherwise show blank
            let blankOrAnswer = selectedAnswer ?? "______"
            let fullText = parts[0] + blankOrAnswer + parts[1]
            
            // Create AttributedString from full text
            var attributedString = AttributedString(fullText)
            
            // Find the range of the blank/answer and apply styling
            if let range = attributedString.range(of: blankOrAnswer) {
                var container = AttributeContainer()
                container.foregroundColor = .blue
                container.font = .system(size: 20, weight: .bold)
                attributedString[range].setAttributes(container)
            }
            
            return Text(attributedString)
        } else {
            // Fallback: just show the sentence
            return Text(sentence)
                .foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    private func translationWithBlurredAnswer(_ translation: String, englishAnswer: String) -> some View {
        // Find the answer word/phrase in the translation (case-insensitive)
        let lowerTranslation = translation.lowercased()
        let lowerAnswer = englishAnswer.lowercased()
        
        if let lowerRange = lowerTranslation.range(of: lowerAnswer) {
            // Convert the range from lowercased string to original string
            let startIndex = translation.index(translation.startIndex, offsetBy: lowerTranslation.distance(from: lowerTranslation.startIndex, to: lowerRange.lowerBound))
            let endIndex = translation.index(translation.startIndex, offsetBy: lowerTranslation.distance(from: lowerTranslation.startIndex, to: lowerRange.upperBound))
            let range = startIndex..<endIndex
            
            // Split the translation into parts
            let beforeRange = translation[..<range.lowerBound]
            let answerRange = translation[range]
            let afterRange = translation[range.upperBound...]
            
            HStack(spacing: 4) {
                Text(String(beforeRange))
                Text(String(answerRange))
                    .blur(radius: 6)
                    .opacity(0.5)
                Text(String(afterRange))
            }
        } else {
            // If answer not found in translation, show as-is
            Text(translation)
        }
    }
    
    // MARK: - Practice Progress Persistence
    private struct AntonymPracticeProgress: Codable {
        let exampleId: Int
        let selectedAnswer: String?
        let showFeedback: Bool
        let isCorrect: Bool
        let questionCount: Int
        let sessionQuestions: Int
        let sessionCorrect: Int
        let sessionWrong: Int
        let shownQuestionIds: [Int]
        let options: [String]
        let correctAnswer: String
        let showTranslation2: Bool
    }
    
    private func savePracticeProgress() {
        guard let example = currentExample else {
            // If no current example, clear any saved progress
            clearPracticeProgress()
            return
        }
        
        let progressData = AntonymPracticeProgress(
            exampleId: example.id,
            selectedAnswer: selectedAnswer,
            showFeedback: showFeedback,
            isCorrect: isCorrect,
            questionCount: questionCount,
            sessionQuestions: sessionQuestions,
            sessionCorrect: sessionCorrect,
            sessionWrong: sessionWrong,
            shownQuestionIds: Array(shownQuestionIds),
            options: options,
            correctAnswer: correctAnswer,
            showTranslation2: showTranslation2
        )
        
        do {
            let encoded = try JSONEncoder().encode(progressData)
            UserDefaults.standard.set(encoded, forKey: practiceProgressKey)
        } catch {
            print("❌ Failed to save antonym practice progress: \(error)")
        }
    }
    
    private func loadPracticeProgress() {
        guard let data = UserDefaults.standard.data(forKey: practiceProgressKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(AntonymPracticeProgress.self, from: data)
            
            // Try to find the original example from AntonymDataManager
            let allExamples = AntonymDataManager.shared.getAllExamples()
            if let originalExample = allExamples.first(where: { $0.id == decoded.exampleId }) {
                currentExample = originalExample
            } else {
                print("❌ Could not find example with id: \(decoded.exampleId)")
                return
            }
            
            // Restore state
            selectedAnswer = decoded.selectedAnswer
            showFeedback = decoded.showFeedback
            isCorrect = decoded.isCorrect
            questionCount = decoded.questionCount
            sessionQuestions = decoded.sessionQuestions
            sessionCorrect = decoded.sessionCorrect
            sessionWrong = decoded.sessionWrong
            shownQuestionIds = Set(decoded.shownQuestionIds)
            options = decoded.options
            correctAnswer = decoded.correctAnswer
            showTranslation2 = decoded.showTranslation2
            
            // Generate audio for the restored example
            if let example = currentExample {
                let sentenceWithAnswer = example.sentence.replacingOccurrences(of: "______", with: example.answer)
                audioManager.generateAudio(for: sentenceWithAnswer, withBeepAt: example.answer)
            }
        } catch {
            print("❌ Failed to load antonym practice progress: \(error)")
            clearPracticeProgress()
        }
    }
    
    private func clearPracticeProgress() {
        UserDefaults.standard.removeObject(forKey: practiceProgressKey)
    }
}
