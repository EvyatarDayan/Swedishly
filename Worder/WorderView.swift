//
//  WorderView.swift
//  SWWorder
//
//  Created by EVYATAR DAYAN on 2026-02-01.
//

import SwiftUI
import UIKit

extension Notification.Name {
    static let worderResetSession = Notification.Name("worderResetSession")
}

// MARK: - Data Models (matches data.json structure)
struct WordOrderExample: Codable, Identifiable {
    let id: Int
    let group: String?
    let sentenceBlocks: [String]
    let answer: String
    let answerTranslation: String
    let tip: String?
    
    enum CodingKeys: String, CodingKey {
        case id, group, answer, tip
        case sentenceBlocks = "sentence_blocks"
        case answerTranslation = "answerTranslation"
    }
}

// MARK: - Data Manager
class WordOrderDataManager {
    static let shared = WordOrderDataManager()
    
    private var examples: [WordOrderExample] = []
    
    init() {
        loadData()
    }
    
    private func loadData() {
        // Prefer Worder/Data/WorderData.json when integrated in Swedishly app
        var url = Bundle.main.url(forResource: "WorderData", withExtension: "json", subdirectory: "Worder/Data")
        if url == nil {
            url = Bundle.main.url(forResource: "WorderData", withExtension: "json")
        }
        if url == nil {
            url = Bundle.main.url(forResource: "data", withExtension: "json")
        }
        guard let url = url else {
            print("Could not find WorderData.json or data.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            examples = try decoder.decode([WordOrderExample].self, from: data)
            print("Loaded \(examples.count) examples from Worder data")
        } catch {
            print("Error loading Worder data: \(error)")
        }
    }
    
    func getAllExamples() -> [WordOrderExample] {
        return examples
    }
    
    func getRandomExample() -> WordOrderExample? {
        return examples.randomElement()
    }
}

// MARK: - Word Chip Button
struct WordChipButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let isDisabled: Bool
    let isAnimating: Bool
    /// 1-based selection order when this chip was selected (shown on chip below; nil = not selected)
    var selectionOrder: Int? = nil
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if let order = selectionOrder {
                        Text("\(order)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color(.systemBackground).opacity(0.9)))
                            .overlay(Circle().stroke(borderColor, lineWidth: 1))
                            .offset(x: -5, y: -5)
                    }
                }
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isAnimating)
        }
        .disabled(isDisabled)
    }
    
    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.15)
        } else if isIncorrect {
            return Color.red.opacity(0.15)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isCorrect {
            return Color.green
        } else if isIncorrect {
            return Color.red
        } else if isSelected {
            return Color.blue
        } else {
            return Color.blue.opacity(0.5)
        }
    }
}

// MARK: - Practice Summary Modal
struct WorderSummaryModal: View {
    let questions: Int
    let correct: Int
    let wrong: Int
    let successPercentage: Int
    let motivationalMessage: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                Text(motivationalMessage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 30)
                        .frame(width: 200, height: 200)
                    Circle()
                        .trim(from: 0, to: correctRatio)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    if wrongRatio > 0 {
                        Circle()
                            .trim(from: correctRatio, to: correctRatio + wrongRatio)
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                    }
                    VStack(spacing: 4) {
                        Text("\(successPercentage)%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Success")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        VStack(spacing: 8) {
                            Text("\(questions)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Questions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        VStack(spacing: 8) {
                            Text("\(correct)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                            Text("Correct")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        VStack(spacing: 8) {
                            Text("\(wrong)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.red)
                            Text("Wrong")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var correctRatio: Double {
        guard questions > 0 else { return 0 }
        return Double(correct) / Double(questions)
    }
    
    private var wrongRatio: Double {
        guard questions > 0 else { return 0 }
        return Double(wrong) / Double(questions)
    }
}

// MARK: - Worder Practice View
struct WorderPracticeView: View {
    @Environment(\.colorScheme) var colorScheme
    /// When provided, limit the practice to this exact list of example IDs (used for retakes).
    var initialExampleIds: [Int]? = nil
    /// Optional completion handler called when a session finishes (questions, correct, questionResults).
    var onSessionComplete: ((Int, Int, [WorderQuestionResult]) -> Void)? = nil
    /// When provided, an explicit ordering of example IDs to present (used for retakes to preserve order).
    var initialExampleOrder: [Int]? = nil
    /// Custom title to display in header (default: "Word Order")
    var customTitle: String = "Practice"
    /// Session limit (default: 20)
    var sessionLimit: Int = 20
    /// Session type for history (default: .wordOrder)
    var sessionType: WorderHistorySessionType = .wordOrder
    /// Optional initial filter to pass to the HistoryView when "Previous practices/tests" is tapped
    var historyInitialFilter: WorderHistoryView.WorderFilterOption? = nil
    @State private var currentExample: WordOrderExample?
    @State private var displayWords: [String] = []
    @State private var selectedIndices: [Int] = []
    @State private var correctAnswer: String = ""
    @State private var correctBlockOrder: [String] = []
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var questionCount: Int = 0
    @State private var showTranslation: Bool = true
    @State private var showUpIcon: Bool = false
    @State private var shownQuestionIds: Set<Int> = []
    @State private var initialOrderIndex: Int = 0
    @State private var selectionQueue: [Int] = []
    @State private var sessionQuestions: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var sessionWrong: Int = 0
    @State private var sessionQuestionResults: [WorderQuestionResult] = []
    @State private var showingSessionSummary: Bool = false
    @State private var showingDoneConfirmation: Bool = false
    @State private var showingTipPopup: Bool = false
    @State private var showCorrectInAnswerArea: Bool = false
    @State private var showWordChips: Bool = false
    @State private var sessionConcluded: Bool = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var myListManager = WorderMyListManager.shared
    
    private var practiceProgressKey: String {
        // Make progress key unique per session type to prevent cross-contamination
        "wordOrderPracticeProgress_\(sessionType.rawValue)"
    }
    
    private var isFavorite: Bool {
        guard let example = currentExample else { return false }
        return myListManager.isInMyList(swedish: example.answer, english: example.answerTranslation)
    }
    
    private var selectedWords: [String] {
        selectedIndices.map { displayWords[$0] }
    }
    
    private var userAnswer: String {
        selectedWords.joined(separator: " ")
    }
    
    private var correctWordCount: Int {
        guard selectedWords.count == correctBlockOrder.count else { return 0 }
        var count = 0
        for (index, word) in selectedWords.enumerated() {
            if index < correctBlockOrder.count && word.lowercased() == correctBlockOrder[index].lowercased() {
                count += 1
            }
        }
        return count
    }
    
    private var feedbackMessage: (text: String, color: Color) {
        let total = correctBlockOrder.count
        guard total > 0 else { return ("Incorrect!", .red) }
        let correct = correctWordCount
        switch correct {
        case 0: return ("Incorrect!", .red)
        case 1: return ("Not quite!", .red)
        case total: return ("Excellent!", .green)
        default: return ("Getting there!", .green)
        }
    }
    
    private func getCorrectBlockOrder(answer: String, blocks: [String]) -> [String] {
        let lowerAnswer = answer.lowercased()
        return blocks.sorted { block1, block2 in
            let pos1 = lowerAnswer.range(of: block1.lowercased())?.lowerBound ?? lowerAnswer.startIndex
            let pos2 = lowerAnswer.range(of: block2.lowercased())?.lowerBound ?? lowerAnswer.startIndex
            return pos1 < pos2
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        ZStack {
            HStack {
                Spacer()
                Text(customTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.appRed)
                Spacer()
            }
            HStack {
                // Favorite (My list) button – same icon as Vocabulary; green when in list
                if currentExample != nil {
                    Button(action: {
                        guard let example = currentExample else { return }
                        if isFavorite {
                            myListManager.removeFromMyList(swedish: example.answer, english: example.answerTranslation)
                        } else {
                            myListManager.addToMyList(swedish: example.answer, english: example.answerTranslation)
                        }
                    }) {
                        Image("My list")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(isFavorite ? .green : .gray)
                    }
                }
                Spacer()
                // Reset/Cancel button (right side)
                if currentExample != nil {
                    Button(action: {
                        // If retaking (initialExampleOrder provided), cancel and dismiss
                        if initialExampleOrder != nil {
                            dismiss()
                        } else {
                            // Otherwise, show reset confirmation
                            showingDoneConfirmation = true
                        }
                    }) {
                        Text(initialExampleOrder != nil ? "Cancel" : "Reset")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private var answerAreaView: some View {
        ZStack {
            // Main content: words (keeps layout stable)
        VStack(spacing: 8) {
            if selectedWords.isEmpty && !showCorrectInAnswerArea {
                Text("Tap words below to build your sentence")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(minHeight: 44)
            } else {
                let wordsToShow: [String] = (showFeedback && showCorrectInAnswerArea) ? correctBlockOrder : selectedWords
                FlowLayout(spacing: 8) {
                    ForEach(Array(wordsToShow.enumerated()), id: \.offset) { index, word in
                        Text(word)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(showCorrectInAnswerArea ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(showCorrectInAnswerArea ? Color.green : Color.blue.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.5), value: showCorrectInAnswerArea)
            }
        }
            // Overlayed audio button on the right — does not affect main layout
            if showFeedback, let example = currentExample {
                HStack {
                    Spacer()
                    Button(action: {
                        if SpeechManager.shared.isSpeaking {
                            SpeechManager.shared.stop()
                        } else {
                            SpeechManager.shared.speak(example.answer, language: "sv-SE")
                        }
                    }) {
                        Image("audio-headphone")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, -10)
                    .padding(.bottom, 92)
                }
                .allowsHitTesting(true)
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 140)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .padding(.bottom, 8)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func scrollContentView(example: WordOrderExample) -> some View {
        VStack(spacing: 0) {
            // Upper part: fixed size, not affected by lower content
            VStack(spacing: 0) {
                Spacer().frame(height: 50)
                answerAreaView
                Spacer().frame(height: 20)
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 5)
                    .padding(.horizontal, 20)
                HStack {
                    Button(action: undoLastWord) {
                        Text("Undo")
                            .font(.body)
                            .foregroundColor(selectedWords.isEmpty || showFeedback ? .gray : .blue)
                    }
                    .disabled(selectedWords.isEmpty || showFeedback)
                    Spacer()
                    if let tip = example.tip, !tip.isEmpty {
                        Button(action: { showingTipPopup = true }) {
                            Text("Info")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(minHeight: 44)
                .padding(.top, 5)
                .padding(.bottom, 25)
                .padding(.horizontal, 20)
                VStack(spacing: 0) {
                    Group {
                        if !showTranslation {
                            Button(action: { withAnimation { showTranslation = true } }) {
                                Text("English translation")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Text(example.answerTranslation)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: showTranslation)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 24)
                }
                .frame(height: 10)
                .padding(.top, -10)
                Spacer().frame(height: 24)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Lower part: flexible, takes remaining space
            VStack(spacing: 16) {
                FlowLayout(spacing: 12) {
                    if showFeedback {
                        ForEach(Array(displayWords.enumerated()), id: \.offset) { index, word in
                            let positionInAnswer = selectedIndices.firstIndex(of: index)
                            let isWordCorrect = positionInAnswer != nil && positionInAnswer! < correctBlockOrder.count && correctBlockOrder[positionInAnswer!].lowercased() == word.lowercased()
                            let order = positionInAnswer.map { $0 + 1 }
                            WordChipButton(
                                text: word,
                                isSelected: true,
                                isCorrect: isWordCorrect,
                                isIncorrect: !isWordCorrect,
                                isDisabled: true,
                                isAnimating: false,
                                selectionOrder: order,
                                action: {}
                            )
                        }
                    } else {
                        ForEach(Array(displayWords.enumerated()), id: \.offset) { index, word in
                            let isSelected = selectedIndices.contains(index)
                            let order = isSelected ? selectedIndices.firstIndex(of: index).map { $0 + 1 } : nil
                            WordChipButton(
                                text: word,
                                isSelected: isSelected,
                                isCorrect: false,
                                isIncorrect: false,
                                isDisabled: isSelected,
                                isAnimating: false,
                                selectionOrder: order,
                                action: { selectWord(at: index) }
                            )
                            .scaleEffect(showWordChips ? 1 : 0.5)
                            .opacity(showWordChips ? 1 : 0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.75)
                                    .delay(showWordChips ? Double(index) * 0.08 : Double(displayWords.count - 1 - index) * 0.08),
                                value: showWordChips
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
            .padding(.bottom, 0)
        }
    }
    
    @ViewBuilder
    private func feedbackSectionView(example: WordOrderExample) -> some View {
        VStack(spacing: 12) {
            if showFeedback {
                Text(feedbackMessage.text)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(feedbackMessage.color)
                // Upper sentence row with audio button shown only after sentence is completed
                HStack(spacing: 12) {
                    Text("Answer: \(example.answer)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                        .multilineTextAlignment(.leading)
//                    Spacer()
//                    Button(action: {
//                        // Toggle playback using the web-TTS player
//                        if SpeechManager.shared.isSpeaking {
//                            SpeechManager.shared.stop()
//                        } else {
//                            SpeechManager.shared.speak(example.answer, language: "sv-SE")
//                        }
//                    }) {
//                        Image("audio-headphone")
//                            .resizable()
//                            .renderingMode(.template)
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 28, height: 28)
//                            .foregroundColor(.blue)
//                    }
//                    .buttonStyle(PlainButtonStyle())
                }
                    .padding(.horizontal, 20)
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
                    Text("Choose the order")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                    .padding(.bottom, 20)
                .animation(.easeInOut(duration: 0.2), value: showUpIcon)
            }
        }
        .frame(minHeight: 80)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .animation(.easeInOut(duration: 0.2), value: showFeedback)
    }
    
    private var startScreenAttributedSubtitle: Text {
        var full = AttributedString(sessionType == .test ? "Test Swedish word order. Arrange " : "Practice Swedish word order. Arrange ")
        let scrambled = AttributedString("scrambled words")
//        scrambled.foregroundColor = .blue
//        scrambled.font = .body.bold()
        full.append(scrambled)
        full.append(AttributedString(sessionType == .test ? " into correct 10 sentences. " : " into correct 20 sentences. "))
        var lycka = AttributedString("Lycka till!")
        lycka.foregroundColor = .blue
        lycka.font = .body.bold()
        full.append(lycka)
        return Text(full)
    }
    
    @ViewBuilder
    private var startScreenView: some View {
        VStack(spacing: 10) {
            Spacer()
//            Image("practice")
            Image(sessionType == .test ? "Test" : "practice")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            startScreenAttributedSubtitle
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .padding(.bottom, 15)
            Button(action: {
                // User-initiated start should force-start even after a concluded session
                sessionConcluded = false
                loadRandomWord(force: true)
            }) {
                Text(sessionType == .test ? "Start new test" : "Start new practice")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            Button(action: {
                NotificationCenter.default.post(name: .openHistoryWithWorderFilter, object: nil)
            }) {
                Text(sessionType == .test ? "Previous tests" : "Previous practices")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 60)
            .padding(.top, 12)

            let lastSession = WorderPracticeHistoryManager.shared.historyItems
                .filter({ $0.effectiveType == sessionType })
                .max(by: { $0.dateTaken < $1.dateTaken })

            Group {
                if let last = lastSession {
                    SessionSuccessRingChart(
                        correct: last.correct,
                        questions: last.questions,
                        dateTaken: last.dateTaken,
                        successPercentage: last.percentage,
                        titlePrefix: sessionType == .test ? "Your last test" : "Your last practice"
                    )
                    .id(last.id)
                } else {
                    SessionSuccessRingChart(
                        correct: 0,
                        questions: 0,
                        dateTaken: Date(),
                        successPercentage: 0,
                        titlePrefix: sessionType == .test ? "Your last test" : "Your last practice",
                        titleOverride: sessionType == .test
                            ? "No test information yet"
                            : "No practice information yet"
                    )
                    .id("worder-empty-\(sessionType.rawValue)")
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()
        }
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Keep initial-screen Back positioning independent from the in-session Back positioning.
            // (BackButtonRow is shared across the app, so we inline it here with conditional padding.)
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.body)
                    }
                    .padding(.top, currentExample == nil ? 60 : 0)
                    .foregroundColor(.appRed)
                }
                .padding(.top, 8)
                .padding(.leading, 4)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            headerView
            
            if let example = currentExample {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, -100)
                        .overlay(alignment: .top) {
                            if questionCount > 0 {
                                let effectiveSessionLimit = max(initialExampleOrder?.count ?? initialExampleIds?.count ?? sessionLimit, 1)
                                let currentQuestion = (questionCount % effectiveSessionLimit == 0 && questionCount > 0) ? effectiveSessionLimit : (questionCount % effectiveSessionLimit)
                                HStack(spacing: 8) {
                                    Text("\(currentQuestion)/\(effectiveSessionLimit)")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("ID: \(example.id)")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
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
                    VStack(spacing: 0) {
                        scrollContentView(example: example)
                            .frame(maxHeight: .infinity)
                        feedbackSectionView(example: example)
                    }
                    Button(action: { nextWord() }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background((showFeedback && sessionQuestions < sessionLimit) ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!showFeedback || sessionQuestions >= sessionLimit)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            } else {
                startScreenView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSessionSummary, onDismiss: { resetToDefaultScreen() }) {
            WorderSummaryModal(
                questions: sessionQuestions,
                correct: sessionCorrect,
                wrong: sessionWrong,
                successPercentage: successPercentage,
                motivationalMessage: motivationalMessage
            )
        }
        .alert("Information", isPresented: $showingTipPopup) {
            Button("OK") {}
        } message: {
            Text(currentExample?.tip ?? "")
        }
        .alert("Are you sure?", isPresented: $showingDoneConfirmation) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) { resetToDefaultScreen() }
        } message: {
            Text("This will reset the current practice")
        }
        .onAppear {
            // If we have an explicit order for retake, start with the first question immediately
            if let order = initialExampleOrder, !order.isEmpty, currentExample == nil {
                // Reset all state for fresh retake
                initialOrderIndex = 0
                questionCount = 0
                sessionQuestions = 0
                sessionCorrect = 0
                sessionWrong = 0
                shownQuestionIds = []
                sessionQuestionResults = []
                
                // Load the first question immediately
                let allExamples = WordOrderDataManager.shared.getAllExamples()
                let firstId = order[0]
                if let firstExample = allExamples.first(where: { $0.id == firstId }) {
                    setupExample(firstExample)
                    questionCount = 1
                    initialOrderIndex = 1
                }
            } else if initialExampleOrder == nil && initialExampleIds == nil && currentExample == nil {
                // Build a selection queue for a fresh practice session using performance-aware sampling
                let effectiveSessionLimit = max(sessionLimit, 1)
                selectionQueue = WorderPracticeHistoryManager.shared.generateSessionExampleIDs(total: effectiveSessionLimit)
                initialOrderIndex = 0
            } else if currentExample == nil {
                // Normal flow: load saved progress or wait for user to click "Start new practice/test"
                loadPracticeProgress()
            }
        }
        .onDisappear {
            savePracticeProgress()
        }
        .onChange(of: currentExample?.id) { _, newValue in
            if newValue != nil { savePracticeProgress() }
        }
        .onChange(of: showFeedback) { _, newValue in
            if newValue { savePracticeProgress() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .worderResetSession)) { _ in
            // Reset the session state immediately when a reset notification is posted
            sessionConcluded = true
            resetToDefaultScreen()
        }
    }
    
    private func loadRandomWord(force: Bool = false) {
        // If the session has been marked concluded (summary shown), ignore any automatically scheduled loads.
        if sessionConcluded && !force { return }
        // Reset session counters when starting a new session batch
        let effectiveSessionLimit = max(initialExampleOrder?.count ?? initialExampleIds?.count ?? sessionLimit, 1)
        if questionCount == 0 || questionCount % effectiveSessionLimit == 0 {
            sessionQuestions = 0
            sessionCorrect = 0
            sessionWrong = 0
            shownQuestionIds = []
            sessionQuestionResults = []
            initialOrderIndex = 0
        }
        questionCount += 1
        let allExamples = WordOrderDataManager.shared.getAllExamples()
        // If initialExampleIds provided, restrict pool to those ids for deterministic retake
        let pool: [WordOrderExample]
        if let ids = initialExampleIds, !ids.isEmpty {
            pool = allExamples.filter { ids.contains($0.id) }
        } else {
            pool = allExamples
        }
        if let order = initialExampleOrder, !order.isEmpty {
            // follow the explicit order provided
            let idx = initialOrderIndex % order.count
            guard idx < order.count else { return }
            let id = order[idx]
            guard let example = pool.first(where: { $0.id == id }) ?? allExamples.first(where: { $0.id == id }) else { return }
            shownQuestionIds.insert(example.id)
            initialOrderIndex += 1
            setupExample(example)
        } else if !selectionQueue.isEmpty {
            // Use precomputed selectionQueue when available (performance-aware sampling)
            let idx = initialOrderIndex % selectionQueue.count
            guard idx < selectionQueue.count else { return }
            let id = selectionQueue[idx]
            guard let example = pool.first(where: { $0.id == id }) ?? allExamples.first(where: { $0.id == id }) else { return }
            shownQuestionIds.insert(example.id)
            initialOrderIndex += 1
            setupExample(example)
        } else {
            let availableExamples = pool.filter { !shownQuestionIds.contains($0.id) }
            guard let example = availableExamples.randomElement() ?? pool.randomElement() else { return }
        shownQuestionIds.insert(example.id)
        setupExample(example)
        }
    }
    
    private func setupExample(_ example: WordOrderExample) {
        currentExample = example
        correctAnswer = example.answer
        correctBlockOrder = getCorrectBlockOrder(answer: example.answer, blocks: example.sentenceBlocks)
        displayWords = example.sentenceBlocks.shuffled()
        selectedIndices = []
        showFeedback = false
        isCorrect = false
        showTranslation = true
        showCorrectInAnswerArea = false
        // Reset animation state and trigger animation
        showWordChips = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showWordChips = true
        }
        // show the small up icon after a short delay to draw attention to the instruction
        showUpIcon = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeIn(duration: 0.25)) {
                showUpIcon = true
            }
        }
    }
    
    private func selectWord(at index: Int) {
        guard index >= 0, index < displayWords.count else { return }
        guard !selectedIndices.contains(index) else { return }
        selectedIndices.append(index)
        if selectedIndices.count == displayWords.count { checkAnswer() }
    }
    
    private func undoLastWord() {
        guard !selectedIndices.isEmpty else { return }
        selectedIndices.removeLast()
    }
    
    private func checkAnswer() {
        isCorrect = userAnswer.trimmingCharacters(in: .whitespaces).lowercased() == correctAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        showFeedback = true
        showTranslation = true
        showCorrectInAnswerArea = false
        // hide the up icon when feedback is shown
        showUpIcon = false
        sessionQuestions += 1
        if isCorrect { sessionCorrect += 1 } else { sessionWrong += 1 }
        // Record per-question result for history detail
        if let currentID = currentExample?.id {
            let qRes = WorderQuestionResult(exampleID: currentID, correct: isCorrect, userAnswer: userAnswer)
            sessionQuestionResults.append(qRes)
            print("[Worder] checkAnswer -> exampleID: \(currentID), isCorrect: \(isCorrect), userAnswer: '\(userAnswer)', correctAnswer: '\(correctAnswer)'")
            print("[Worder] sessionQuestions: \(sessionQuestions), sessionCorrect: \(sessionCorrect), sessionWrong: \(sessionWrong), sessionQuestionResults.count: \(sessionQuestionResults.count)")
            print("[Worder] lastQuestionResult: \(qRes)")
        } else {
            print("[Worder] checkAnswer -> currentExample is nil; userAnswer: '\(userAnswer)', correctAnswer: '\(correctAnswer)', isCorrect: \(isCorrect)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.5)) { showCorrectInAnswerArea = true }
        }
        let effectiveSessionLimit = max(initialExampleOrder?.count ?? initialExampleIds?.count ?? sessionLimit, 1)
        if sessionQuestions >= effectiveSessionLimit {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let completion = onSessionComplete {
                    print("[Worder] Session complete -> calling onSessionComplete; questions:\(sessionQuestions) correct:\(sessionCorrect) results:\(sessionQuestionResults.count)")
                    completion(sessionQuestions, sessionCorrect, sessionQuestionResults)
                } else {
                    print("[Worder] Session complete -> saving history via PracticeHistoryManager.addSession; questions:\(sessionQuestions) correct:\(sessionCorrect) results:\(sessionQuestionResults.count)")
                    WorderPracticeHistoryManager.shared.addSession(questions: sessionQuestions, correct: sessionCorrect, exampleIDs: initialExampleIds, questionResults: sessionQuestionResults, sessionType: sessionType)
                showingSessionSummary = true
                }
            }
        }
    }
    
    private func nextWord() {
        let effectiveSessionLimit = max(initialExampleOrder?.count ?? initialExampleIds?.count ?? sessionLimit, 1)
        if sessionQuestions >= effectiveSessionLimit { return }
        loadRandomWord()
    }
    
    private var successPercentage: Int {
        guard sessionQuestions > 0 else { return 0 }
        return Int((Double(sessionCorrect) / Double(sessionQuestions)) * 100)
    }
    
    private var motivationalMessage: String {
        switch successPercentage {
        case 0...25: return "Keep practicing, you can do it!"
        case 26...50: return "You're making progress, keep going!"
        case 51...75: return "Great job! You're doing well!"
        case 76...100: return "Excellent work! You're mastering this!"
        default: return "Keep practicing!"
        }
    }
    
    private func resetToDefaultScreen() {
        clearPracticeProgress()
        currentExample = nil
        displayWords = []
        selectedIndices = []
        showFeedback = false
        isCorrect = false
        showTranslation = false
        questionCount = 0
        correctAnswer = ""
        correctBlockOrder = []
        showCorrectInAnswerArea = false
        sessionQuestions = 0
        sessionCorrect = 0
        sessionWrong = 0
        shownQuestionIds = []
        sessionQuestionResults = []
        showUpIcon = false
    }
    
    private struct WordOrderPracticeProgress: Codable {
        let exampleId: Int
        let displayWords: [String]
        let selectedIndices: [Int]
        let showFeedback: Bool
        let isCorrect: Bool
        let questionCount: Int
        let sessionQuestions: Int
        let sessionCorrect: Int
        let sessionWrong: Int
        let shownQuestionIds: [Int]
        let correctAnswer: String
        let showTranslation: Bool
    }
    
    private func savePracticeProgress() {
        guard let example = currentExample else { clearPracticeProgress(); return }
        let progressData = WordOrderPracticeProgress(
            exampleId: example.id,
            displayWords: displayWords,
            selectedIndices: selectedIndices,
            showFeedback: showFeedback,
            isCorrect: isCorrect,
            questionCount: questionCount,
            sessionQuestions: sessionQuestions,
            sessionCorrect: sessionCorrect,
            sessionWrong: sessionWrong,
            shownQuestionIds: Array(shownQuestionIds),
            correctAnswer: correctAnswer,
            showTranslation: showTranslation
        )
        do {
            let encoded = try JSONEncoder().encode(progressData)
            UserDefaults.standard.set(encoded, forKey: practiceProgressKey)
        } catch {
            print("Failed to save word order progress: \(error)")
        }
    }
    
    private func loadPracticeProgress() {
        guard let data = UserDefaults.standard.data(forKey: practiceProgressKey) else { return }
        do {
            let decoded = try JSONDecoder().decode(WordOrderPracticeProgress.self, from: data)
            let allExamples = WordOrderDataManager.shared.getAllExamples()
            guard let originalExample = allExamples.first(where: { $0.id == decoded.exampleId }) else { return }
            currentExample = originalExample
            displayWords = decoded.displayWords
            selectedIndices = decoded.selectedIndices
            showFeedback = decoded.showFeedback
            isCorrect = decoded.isCorrect
            questionCount = decoded.questionCount
            sessionQuestions = decoded.sessionQuestions
            sessionCorrect = decoded.sessionCorrect
            sessionWrong = decoded.sessionWrong
            shownQuestionIds = Set(decoded.shownQuestionIds)
            correctAnswer = decoded.correctAnswer
            showTranslation = decoded.showTranslation
            if let example = currentExample {
                correctBlockOrder = getCorrectBlockOrder(answer: decoded.correctAnswer, blocks: example.sentenceBlocks)
            }
            // Show words immediately when loading from saved progress (no animation delay)
            if !displayWords.isEmpty {
                showWordChips = true
            }
        } catch {
            clearPracticeProgress()
        }
    }
    
    private func clearPracticeProgress() {
        UserDefaults.standard.removeObject(forKey: practiceProgressKey)
    }
}

// MARK: - Flow Layout for word chips (centers each line horizontally)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var lineStartIndex = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                let lineWidth = currentX - spacing
                let xOffset = (maxWidth - lineWidth) / 2
                for i in lineStartIndex..<positions.count { positions[i].x += xOffset }
                lineStartIndex = positions.count
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        if lineStartIndex < positions.count {
            let lineWidth = currentX - spacing
            let xOffset = (maxWidth - lineWidth) / 2
            for i in lineStartIndex..<positions.count { positions[i].x += xOffset }
        }
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Placeholder History Sheet
struct WorderHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                Text("Your practice history will appear here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Previous Practices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
