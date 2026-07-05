//
//  VerbDetailView.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI
import AVFoundation
import Foundation

struct VerbDetailView: View {
    let verb: Verb
    let isPracticeMode: Bool
    let isTestMode: Bool
    let testId: String?
    @Environment(\.dismiss) var dismiss
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @StateObject private var favoriteManager = FavoriteManager.shared
    @StateObject private var testManager = TestManager.shared
    @State private var isFavorite: Bool
    @State private var testAnswers: [String: String] = [:] // title -> answer
    @State private var testResults: [String: Bool] = [:] // title -> isCorrect
    @State private var isPlayingInfinitive = false
    @State private var isAnswerInputShowing = false // Track if any answer input popup is showing
    
    private var hasAnyAnswer: Bool {
        // Infinitive audio button is always enabled
        // Individual example audio buttons are controlled in ExampleCard
        return true
    }
    
    init(verb: Verb, isPracticeMode: Bool = false, isTestMode: Bool = false, testId: String? = nil) {
        self.verb = verb
        self.isPracticeMode = isPracticeMode
        self.isTestMode = isTestMode
        self.testId = testId
        _isFavorite = State(initialValue: FavoriteManager.shared.isFavorite(verb))
        
        // Load saved answers if in test mode
        if isTestMode, let testId = testId {
            let (savedAnswers, savedResults) = TestManager.shared.getVerbAnswers(testId: testId, verbId: verb.id)
            _testAnswers = State(initialValue: savedAnswers)
            _testResults = State(initialValue: savedResults)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 5)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        
                        // Header
                    VStack(alignment: .center, spacing: 8) {
                        HStack(spacing: 12) {
                            Text(verb.infinitive)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                if isPlayingInfinitive {
                                    speechSynthesizer.stop()
                                    isPlayingInfinitive = false
                                } else {
                                    // Stop any other playing audio
                                    if speechSynthesizer.isSpeaking {
                                        speechSynthesizer.stop()
                                    }
                                    
                                    speechSynthesizer.speak(verb.infinitive, language: "sv-SE") {
                                        isPlayingInfinitive = false
                                    }
                                    isPlayingInfinitive = true
                                }
                            }) {
                                Image("audio-headphone")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .opacity(isPlayingInfinitive ? 0.5 : 1.0)
                                    .animation(
                                        isPlayingInfinitive ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                                        value: isPlayingInfinitive
                                    )
                                    .foregroundColor((isTestMode || isPracticeMode) && !hasAnyAnswer ? .gray : .blue)
                            }
                            .buttonStyle(.plain)
                            .disabled((isTestMode || isPracticeMode) && !hasAnyAnswer)
                        }
                        
                        if !verb.english.isEmpty && verb.english[0] != "translation" {
                            Text(verb.english.joined(separator: ", "))
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 5)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    
                    // Examples Section
                    VStack(alignment: .leading, spacing: 16) {
                        // Present Tense
                        ExampleCard(
                            title: "Present",
                            swedish: verb.examples.present.sv,
                            english: verb.examples.present.en,
                            verbBase: verb.base,
                            speechSynthesizer: speechSynthesizer,
                            isPracticeMode: isPracticeMode,
                            isTestMode: isTestMode,
                            answer: Binding(
                                get: { testAnswers["Present"] ?? "" },
                                set: { 
                                    testAnswers["Present"] = $0
                                    // Save answers immediately when changed
                                    if isTestMode, let testId = testId {
                                        var updatedAnswers = testAnswers
                                        updatedAnswers["Present"] = $0
                                        testManager.updateVerbAnswers(testId: testId, verbId: verb.id, answers: updatedAnswers, results: testResults)
                                    }
                                }
                            ),
                            isCorrect: Binding(
                                get: { testResults["Present"] ?? false },
                                set: { 
                                    testResults["Present"] = $0
                                    // Save results immediately when changed
                                    if isTestMode, let testId = testId {
                                        var updatedResults = testResults
                                        updatedResults["Present"] = $0
                                        testManager.updateVerbAnswers(testId: testId, verbId: verb.id, answers: testAnswers, results: updatedResults)
                                    }
                                }
                            ),
                            isAnswerInputShowing: $isAnswerInputShowing
                        )
                        
                        // Past Tense
                        ExampleCard(
                            title: "Past",
                            swedish: verb.examples.past.sv,
                            english: verb.examples.past.en,
                            verbBase: verb.base,
                            speechSynthesizer: speechSynthesizer,
                            isPracticeMode: isPracticeMode,
                            isTestMode: isTestMode,
                            answer: Binding(
                                get: { testAnswers["Past"] ?? "" },
                                set: { 
                                    testAnswers["Past"] = $0
                                    // Save answers immediately when changed
                                    if isTestMode, let testId = testId {
                                        var updatedAnswers = testAnswers
                                        updatedAnswers["Past"] = $0
                                        testManager.updateVerbAnswers(testId: testId, verbId: verb.id, answers: updatedAnswers, results: testResults)
                                    }
                                }
                            ),
                            isCorrect: Binding(
                                get: { testResults["Past"] ?? false },
                                set: { 
                                    testResults["Past"] = $0
                                    // Save results immediately when changed
                                    if isTestMode, let testId = testId {
                                        var updatedResults = testResults
                                        updatedResults["Past"] = $0
                                        testManager.updateVerbAnswers(testId: testId, verbId: verb.id, answers: testAnswers, results: updatedResults)
                                    }
                                }
                            ),
                            isAnswerInputShowing: $isAnswerInputShowing
                        )
                        
                        // Perfect Tense
                        ExampleCard(
                            title: "Perfect",
                            swedish: verb.examples.perfect.sv,
                            english: verb.examples.perfect.en,
                            verbBase: verb.base,
                            speechSynthesizer: speechSynthesizer,
                            isPracticeMode: isPracticeMode,
                            isTestMode: isTestMode,
                            answer: Binding(
                                get: { testAnswers["Perfect"] ?? "" },
                                set: { 
                                    testAnswers["Perfect"] = $0
                                    // Save answers immediately when changed
                                    if isTestMode, let testId = testId {
                                        var updatedAnswers = testAnswers
                                        updatedAnswers["Perfect"] = $0
                                        testManager.updateVerbAnswers(testId: testId, verbId: verb.id, answers: updatedAnswers, results: testResults)
                                    }
                                }
                            ),
                            isCorrect: Binding(
                                get: { testResults["Perfect"] ?? false },
                                set: { 
                                    testResults["Perfect"] = $0
                                    // Save results immediately when changed
                                    if isTestMode, let testId = testId {
                                        var updatedResults = testResults
                                        updatedResults["Perfect"] = $0
                                        testManager.updateVerbAnswers(testId: testId, verbId: verb.id, answers: testAnswers, results: updatedResults)
                                    }
                                }
                            ),
                            isAnswerInputShowing: $isAnswerInputShowing
                        )
                    }
                    .padding(.top, 8)
                    }
                    .padding()
                    .padding(.bottom, 90)
                }
                
                // Done button at bottom - hide when answer input is showing (for test/practice modes)
                if !isAnswerInputShowing {
                    VStack(spacing: 0) {
                        Button(action: {
                            // Answers are already saved immediately when changed
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 100)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                    }
                    .background(Color(.systemBackground))
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        favoriteManager.toggleFavorite(verb)
                    }) {
                        MyListFavoriteIcon(isInList: isFavorite)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onChange(of: favoriteManager.favorites) { oldValue, newValue in
                isFavorite = favoriteManager.isFavorite(verb)
            }
            .onChange(of: speechSynthesizer.isSpeaking) { oldValue, newValue in
                if !newValue {
                    isPlayingInfinitive = false
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ExampleCard: View {
    let title: String
    let swedish: String
    let english: String
    let verbBase: String
    @ObservedObject var speechSynthesizer: SpeechSynthesizer
    let isPracticeMode: Bool
    let isTestMode: Bool
    @Binding var answer: String
    @Binding var isCorrect: Bool
    @Binding var isAnswerInputShowing: Bool
    @State private var isPlayingSwedish = false
    @State private var isPlayingEnglish = false
    @State private var revealedVerbs: Set<String> = []
    @State private var showAnswerInput = false
    @State private var inputText = ""
    @Environment(\.colorScheme) var colorScheme
    
    private var isAudioDisabled: Bool {
        if isTestMode {
            return answer.isEmpty
        } else if isPracticeMode {
            let extractedVerb = extractVerbFromSentence(swedish, base: verbBase)
            return extractedVerb != nil && !revealedVerbs.contains(extractedVerb!)
        }
        return false // Always enabled in normal mode
    }
    
    private var correctVerb: String? {
        extractVerbFromSentence(swedish, base: verbBase)
    }
    
    private func extractVerbFromSentence(_ sentence: String, base: String) -> String? {
        // Split sentence into words and clean them
        let words = sentence.components(separatedBy: .whitespaces).map { $0.trimmingCharacters(in: .punctuationCharacters) }
        
        // For perfect tense: "Jag har kommit" - verb is after "har"
        if let harIndex = words.firstIndex(where: { $0.lowercased() == "har" }) {
            if harIndex + 1 < words.count {
                return words[harIndex + 1]
            }
        }
        
        // For present/past: "Jag kommer" or "Jag var" - verb is after "Jag"
        if let jagIndex = words.firstIndex(where: { $0.lowercased() == "jag" }) {
            if jagIndex + 1 < words.count {
                return words[jagIndex + 1]
            }
        }
        
        return nil
    }
    
    private func splitSentence(_ sentence: String, verb: String) -> (before: String, verb: String, after: String)? {
        // Find the verb in the sentence
        let escapedVerb = NSRegularExpression.escapedPattern(for: verb)
        let pattern = "\\b\(escapedVerb)\\b"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: sentence.utf16.count)
        guard let match = regex.firstMatch(in: sentence, options: [], range: range) else {
            return nil
        }
        
        let verbRange = match.range
        let beforeRange = NSRange(location: 0, length: verbRange.location)
        let afterLocation = verbRange.location + verbRange.length
        let afterLength = sentence.utf16.count - afterLocation
        let afterRange = NSRange(location: afterLocation, length: afterLength)
        
        let before = (sentence as NSString).substring(with: beforeRange)
        let verbText = (sentence as NSString).substring(with: verbRange)
        let after = (sentence as NSString).substring(with: afterRange)
        
        return (before, verbText, after)
    }
    
    private func extractVerbFromEnglishSentence(_ sentence: String) -> String? {
        // Split sentence into words and clean them
        let words = sentence.components(separatedBy: .whitespaces).map { $0.trimmingCharacters(in: .punctuationCharacters) }
        
        // For perfect tense: "I have been already." - verb is after "have"
        if let haveIndex = words.firstIndex(where: { $0.lowercased() == "have" }) {
            if haveIndex + 1 < words.count {
                return words[haveIndex + 1]
            }
        }
        
        // For present/past: "I am every day." or "I was yesterday." - verb is after "I"
        if let iIndex = words.firstIndex(where: { $0.lowercased() == "i" }) {
            if iIndex + 1 < words.count {
                return words[iIndex + 1]
            }
        }
        
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Swedish text with play button
                HStack(spacing: 8) {
                    if isTestMode {
                        // Test mode: show blurred verb that opens input
                        if let verb = correctVerb, let parts = splitSentence(swedish, verb: verb) {
                            HStack(spacing: 0) {
                                Text(parts.before)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                
                                Text(parts.verb)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(isCorrect ? .green : (answer.isEmpty ? .primary : .red))
                                    .blur(radius: answer.isEmpty ? 8 : 0)
                                    .onTapGesture {
                                        if answer.isEmpty {
                                            isAnswerInputShowing = true
                                            showAnswerInput = true
                                        }
                                    }
                                
                                Text(parts.after)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        } else {
                            Text(swedish)
                                .font(.title3)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    } else if isPracticeMode {
                        // Make the sentence tappable to reveal hidden verbs
                        let extractedVerb = extractVerbFromSentence(swedish, base: verbBase)
                        let isRevealed = extractedVerb != nil && revealedVerbs.contains(extractedVerb!)
                        
                        if let verb = extractedVerb, let parts = splitSentence(swedish, verb: verb) {
                            // Display sentence with blurred verb
                            HStack(spacing: 0) {
                                Text(parts.before)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                
                                Text(parts.verb)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .blur(radius: isRevealed ? 0 : 8)
                                    .onTapGesture {
                                        if !isRevealed {
                                            revealedVerbs.insert(verb)
                                        }
                                    }
                                
                                Text(parts.after)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        } else {
                            Text(swedish)
                                .font(.title3)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    } else {
                        // Normal mode: show sentence with bold verb
                        if let verb = correctVerb, let parts = splitSentence(swedish, verb: verb) {
                            HStack(spacing: 0) {
                                Text(parts.before)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                
                                Text(parts.verb)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(parts.after)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        } else {
                            Text(swedish)
                                .font(.title3)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if isPlayingSwedish {
                            speechSynthesizer.stop()
                            isPlayingSwedish = false
                        } else {
                            speechSynthesizer.speak(swedish, language: "sv-SE") {
                                isPlayingSwedish = false
                            }
                            isPlayingSwedish = true
                        }
                    }) {
                        Image("audio-headphone")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .opacity(isPlayingSwedish ? 0.5 : 1.0)
                            .animation(
                                isPlayingSwedish ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                                value: isPlayingSwedish
                            )
                            .foregroundColor(isAudioDisabled ? .gray : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAudioDisabled)
                }
                
                // English text
                Group {
                    if let verb = extractVerbFromEnglishSentence(english), let parts = splitSentence(english, verb: verb) {
                        HStack(spacing: 0) {
                            Text(parts.before)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                            
                            Text(parts.verb)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .italic()
                            
                            Text(parts.after)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    } else {
                        Text(english)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .overlay(
            Group {
                if showAnswerInput {
                    AnswerInputView(
                        title: title,
                        correctAnswer: correctVerb ?? "",
                        answer: $answer,
                        isCorrect: $isCorrect,
                        isPresented: Binding(
                            get: { showAnswerInput },
                            set: { 
                                showAnswerInput = $0
                                isAnswerInputShowing = $0
                            }
                        )
                    )
                }
            }
        )
    }
}

struct AnswerInputView: View {
    let title: String
    let correctAnswer: String
    @Binding var answer: String
    @Binding var isCorrect: Bool
    @Binding var isPresented: Bool
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Popup content
            VStack(spacing: 16) {
                Text("Type the \(title) verb")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Your answer...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                    .submitLabel(.done)
                    .onSubmit {
                        submitAnswer()
                    }
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    
                    Button("Verify") {
                        submitAnswer()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(8)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
    
    private func submitAnswer() {
        answer = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        isCorrect = answer.lowercased() == correctAnswer.lowercased()
        isPresented = false
    }
}

#Preview("Verb Detail View") {
    VerbDetailView(verb: Verb(
        infinitive: "att vara",
        base: "vara",
        english: ["to be"],
        regular: false,
        examples: VerbExamples(
            present: VerbsExample(sv: "Jag är", en: "I am"),
            past: VerbsExample(sv: "Jag var", en: "I was"),
            perfect: VerbsExample(sv: "Jag har varit", en: "I have been")
        )
    ))
}

