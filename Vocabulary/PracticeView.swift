import SwiftUI
import UIKit

struct PracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var testDataManager = TestDataManager.shared
    @StateObject private var audioManager = AudioManager()
    @StateObject private var wrongAnswersManager = WrongAnswersManager.shared
    @StateObject private var practiceHistoryManager = PracticeHistoryManager.shared
    @StateObject private var wordStateManager = WordStateManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var currentWord: TestWord?
    @State private var options: [String] = []
    @State private var correctAnswer: String = ""
    @State private var selectedAnswer: String?
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var questionCount: Int = 0
    @State private var isFromWrongAnswers: Bool = false // Track if current word is from wrong answers list
    @State private var showWhy: Bool = false // Track if "Why?" is shown
    @State private var exampleLanguage: String = "sv" // Track which language to show: "sv" or "en"
    @State private var shownWordsInSession: Set<String> = [] // Track words shown in current 20-word session
    @State private var sessionWordPool: [TestWord] = [] // Pool of 20 words for current session with proper distribution
    
    // Practice session state - persisted across app restarts
    private let practiceProgressKey = "practiceProgress"
    
    // Session statistics (for current session only)
    @State private var sessionQuestions: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var sessionWrong: Int = 0
    @State private var sessionQuestionDetails: [PracticeQuestionSummary] = []
    @State private var showingSessionSummary: Bool = false
    @State private var showingDoneConfirmation: Bool = false
    @State private var swedishWordFontSize: CGFloat = 48 // Dynamic font size
    @State private var animatedOptionIndex: Int? = nil // Track which option is animating
    @State private var visibleLetterCount: Int = 0 // For letter-by-letter animation
    @State private var showAudioButton: Bool = false // Show audio button after animation
    @State private var showUpIcon: Bool = false // Show up icon after animation
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                // Centered title
                HStack {
                    Spacer()
                    Text("Practice")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                // Left side - Back button (always) + My list button (when in practice session)
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                    }
                    if currentWord != nil {
                        MyListButton(word: currentWord!)
                    }
                    Spacer()
                }
                
                // Right side - Done button (only show when in practice session)
                HStack {
                    Spacer()
                    if currentWord != nil {
                        Button(action: {
                            // Show confirmation dialog first
                            showingDoneConfirmation = true
                        }) {
                            Text("Reset")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            if let word = currentWord {
                VStack(spacing: 0) {
                    // Horizontal divider above
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, -100)
                        .overlay(alignment: .top) {
                            // Progress indicator overlay centered horizontally on top of divider
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
                    // Content area
                    VStack(spacing: 30) {
     
                        
                        // Swedish word display
                        VStack(spacing: 16) {
                            Text("What is the English translation for:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 12) {
                                    Spacer()
                                    letterByLetterText(word.swedish)
                                        .font(.system(size: swedishWordFontSize, weight: .bold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5) // Allow scaling down to 50% if needed
                                        .fixedSize(horizontal: false, vertical: true)
                                        .layoutPriority(1)
                                    
                                    if showAudioButton {
                                        Button(action: {
                                            audioManager.playAudio()
                                        }) {
                                            Image("audio-headphone")
                                                .resizable()
                                                .renderingMode(.template)
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 40, height: 40)
                                                .foregroundColor(audioManager.isAudioReady ? .blue : .gray)
                                                .opacity(audioManager.isPlaying ? 0.5 : 1.0)
                                        }
                                        .disabled(audioManager.isPlaying || !audioManager.isAudioReady)
                                        .transition(.opacity)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .onAppear {
                                    calculateOptimalFontSize(for: word.swedish, availableWidth: geometry.size.width)
                                    // Animate word appearance
                                    animateWordAppearance()
                                }
                                .onChange(of: currentWord?.swedish) { oldValue, newValue in
                                    if let newValue = newValue {
                                        calculateOptimalFontSize(for: newValue, availableWidth: geometry.size.width)
                                        // Animate word appearance when it changes
                                        animateWordAppearance()
                                    }
                                }
                            }
                            .frame(height: 60) // Fixed height for the HStack
                        }
                        .padding(.top, 60)
                        
                        // Horizontal divider below
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 5)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 2)
                        
                        // Options
                        VStack(spacing: 16) {
                            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                                OptionButton(
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
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Feedback labels
                        VStack(spacing: 12) {
                            if showFeedback {
                                Text(isCorrect ? "Correct!" : "Incorrect!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(isCorrect ? .green : .red)
                                    .padding(.top, 16)
                                
                                // "Example" button - show for both correct and incorrect answers
                                if let word = currentWord {
                                    // Check if we have example data (prefer example over sentence)
                                    let hasExample = word.example != nil
                                    let hasSentence = word.sentence != nil && !word.sentence!.isEmpty
                                    
                                    if hasExample || hasSentence {
                                        if !showWhy {
                                            // Show "Example" button
                                            Button(action: {
                                                withAnimation {
                                                    showWhy = true
                                                    exampleLanguage = "sv" // Reset to Swedish when showing
                                                }
                                            }) {
                                                Text("Example")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.blue)
                                                    .underline()
                                            }
                                            .padding(.top, 8)
                                        } else {
                                            // Show sentence - tappable to toggle language
                                            HStack {
                                                Spacer()
                                                if hasExample, let example = word.example {
                                                    if exampleLanguage == "sv" {
                                                        // Swedish: make the word bold
                                                        makeBoldWordSentence(text: example.sv, wordToBold: word.swedish)
                                                            .font(.system(size: 16))
                                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                                            .italic()
                                                            .multilineTextAlignment(.center)
                                                    } else {
                                                        // English: plain text
                                                        Text(example.en)
                                                            .font(.system(size: 16))
                                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                                            .italic()
                                                            .multilineTextAlignment(.center)
                                                    }
                                                } else if hasSentence, let sentence = word.sentence {
                                                    // Fallback to sentence if example not available
                                                    if exampleLanguage == "sv" {
                                                        // Swedish: make the word bold
                                                        makeBoldWordSentence(text: sentence, wordToBold: word.swedish)
                                                            .font(.system(size: 16))
                                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                                            .italic()
                                                            .multilineTextAlignment(.center)
                                                    } else {
                                                        // English: plain text (though sentence is usually Swedish)
                                                        Text(sentence)
                                                            .font(.system(size: 16))
                                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                                            .italic()
                                                            .multilineTextAlignment(.center)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation {
                                                    exampleLanguage = exampleLanguage == "sv" ? "en" : "sv"
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.top, 8)
                                            .transition(.opacity)
                                        }
                                    }
                                }
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
                                .padding(.top, 16)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: showFeedback)
                        .animation(.easeInOut(duration: 0.2), value: showWhy)
                        
                        Spacer()
                    }
                    
                    // Next button - fixed at bottom (disabled after 20 questions or if no answer selected)
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
                    .padding(.bottom, 20)
                }
            } else {
                // Default/empty state - similar to TestView
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image("practice")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("Master Swedish: Match the words and test your skills. Lycka till!")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
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
                        NotificationCenter.default.post(name: .openHistoryWithVocabularyFilter, object: nil)
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
                    
                    // Last completed 20-question session (or 0% when none yet)
                    LastSessionPieChart(
                        practiceItem: practiceHistoryManager.historyItems.first(where: { $0.questions == 20 })
                    )
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // Load practice progress when view appears (only if we don't already have a word)
            if currentWord == nil {
                loadPracticeProgress()
            }
        }
        .onChange(of: currentWord) { oldValue, newValue in
            if let word = newValue {
                audioManager.generateAudio(for: word.swedish)
                // Reset font size to default when word changes
                swedishWordFontSize = 48
            }
            // Save progress when word changes
            if newValue != nil {
                savePracticeProgress()
            }
        }
        .onChange(of: selectedAnswer) { oldValue, newValue in
            // Save progress when answer is selected
            if newValue != nil {
                savePracticeProgress()
            }
        }
        .onDisappear {
            // Save progress when view disappears
            savePracticeProgress()
            audioManager.cleanupAudio()
        }
        .alert("Are you sure?", isPresented: $showingDoneConfirmation) {
            Button("No", role: .cancel) {
                // Stay in practice session - do nothing
            }
            Button("Yes", role: .destructive) {
                // Reset to initial view without showing summary when user terminates session
                resetToDefaultScreen()
            }
        } message: {
            Text("This will reset the current practice")
        }
        .sheet(isPresented: $showingSessionSummary, onDismiss: {
            // Called when sheet is dismissed (either by button or swipe down)
            resetToDefaultScreen()
        }) {
            PracticeSummaryModal(
                questions: sessionQuestions,
                correct: sessionCorrect,
                wrong: sessionWrong,
                successPercentage: successPercentage,
                motivationalMessage: motivationalMessage
            )
        }
    }
    
    private func loadRandomWord() {
        // Reset session statistics and shown words if this is the first question of a new 20-word session
        if questionCount == 0 || questionCount % 20 == 0 {
            sessionQuestions = 0
            sessionCorrect = 0
            sessionWrong = 0
            sessionQuestionDetails = []
            shownWordsInSession = [] // Reset shown words for new 20-word session
            buildSessionPool() // Build a new pool of 20 words with proper distribution
        }
        
        questionCount += 1
        
        // Helper function to create a unique key for a word
        func wordKey(swedish: String, english: String) -> String {
            return "\(swedish.lowercased()):\(english.lowercased())"
        }
        
        // Select from the session pool, excluding already shown words
        let availableFromPool = sessionWordPool.filter { word in
            let key = wordKey(swedish: word.swedish, english: word.english)
            return !shownWordsInSession.contains(key)
        }
        
        guard let word = availableFromPool.randomElement() else {
            // Pool exhausted or all words shown, rebuild pool
            buildSessionPool()
            
            // Try again with new pool
            let newAvailableFromPool = sessionWordPool.filter { word in
                let key = wordKey(swedish: word.swedish, english: word.english)
                return !shownWordsInSession.contains(key)
            }
            
            guard let fallbackWord = newAvailableFromPool.randomElement() ?? sessionWordPool.randomElement() else {
                // Last resort: get any word from TestDataManager
                let allWords = testDataManager.getAllWords()
                guard let lastResortWord = allWords.randomElement() else {
                    print("❌ No words available")
                    return
                }
                setupWord(lastResortWord, isFromWrongAnswers: false)
                return
            }
            
            setupWord(fallbackWord, isFromWrongAnswers: wordStateManager.getWordState(swedish: fallbackWord.swedish, english: fallbackWord.english) == .weak)
            return
        }
        
        // Check if word is from weak state
        let isWeak = wordStateManager.getWordState(swedish: word.swedish, english: word.english) == .weak
        setupWord(word, isFromWrongAnswers: isWeak)
    }
    
    private func setupWord(_ word: TestWord, isFromWrongAnswers isWeak: Bool) {
        // Helper function to create a unique key for a word
        func wordKey(swedish: String, english: String) -> String {
            return "\(swedish.lowercased()):\(english.lowercased())"
        }
        
        // Mark this word as shown
        shownWordsInSession.insert(wordKey(swedish: word.swedish, english: word.english))
        // Track that this word was seen (for cooldown purposes)
        wordStateManager.markWordAsSeen(swedish: word.swedish, english: word.english)
        
        currentWord = word
        correctAnswer = word.english
        isFromWrongAnswers = isWeak
        
        // Generate options: 1 correct + 2 random incorrect
        generateOptions(for: word)
        
        // Generate audio for the new word
        audioManager.generateAudio(for: word.swedish)
        
        // Reset state
        selectedAnswer = nil
        showFeedback = false
        isCorrect = false
        showWhy = false
        exampleLanguage = "sv" // Reset to Swedish
    }
    
    private func buildSessionPool() {
        // Build a pool of 20 words with the specified distribution:
        // 30% weak = 6 words
        // 25% learning = 5 words
        // 25% new = 5 words
        // 20% review = 4 words
        // 0-5% mastered = 0-1 word (optional)
        
        let now = Date()
        var pool: [TestWord] = []
        
        // Helper function to create a unique key for a word
        func wordKey(swedish: String, english: String) -> String {
            return "\(swedish.lowercased()):\(english.lowercased())"
        }
        
        // Helper function to check if word is available (cooldown check)
        func isAvailable(stateData: WordStateData, minCooldown: TimeInterval) -> Bool {
            if let lastSeen = stateData.lastSeen {
                let timeSinceSeen = now.timeIntervalSince(lastSeen)
                return timeSinceSeen >= minCooldown
            }
            return true
        }
        
        // Helper function to get TestWord from WordStateData
        func getTestWord(from stateData: WordStateData) -> TestWord? {
            return testDataManager.getWordsByContent(swedish: stateData.swedish, english: stateData.english)
        }
        
        // 1. Get 6 weak words (30%)
        let weakWords = wordStateManager.getWordsByState(.weak)
            .filter { isAvailable(stateData: $0, minCooldown: 180) } // 3 min cooldown
            .shuffled()
            .prefix(6)
            .compactMap { getTestWord(from: $0) }
        pool.append(contentsOf: weakWords)
        
        // 2. Get 5 learning words (25%)
        let learningWords = wordStateManager.getWordsByState(.learning)
            .filter { isAvailable(stateData: $0, minCooldown: 120) } // 2 min cooldown
            .shuffled()
            .prefix(5)
            .compactMap { getTestWord(from: $0) }
        pool.append(contentsOf: learningWords)
        
        // 3. Get 5 new words (25%) - words not in the state system yet
        let allWords = testDataManager.getAllWords()
        let allStateWords = wordStateManager.getAllWordStates()
        let stateKeys = Set(allStateWords.map { wordKey(swedish: $0.swedish, english: $0.english) })
        let masteredWords = wordStateManager.getWordsByState(.mastered)
        let masteredKeys = Set(masteredWords.map { wordKey(swedish: $0.swedish, english: $0.english) })
        
        let newWords = allWords
            .filter { word in
                let key = wordKey(swedish: word.swedish, english: word.english)
                return !stateKeys.contains(key) && !masteredKeys.contains(key)
            }
            .shuffled()
            .prefix(5)
        pool.append(contentsOf: newWords)
        
        // 4. Get 4 review words (20%)
        let reviewWords = wordStateManager.getWordsByState(.review)
            .filter { isAvailable(stateData: $0, minCooldown: 600) } // 10 min cooldown
            .shuffled()
            .prefix(4)
            .compactMap { getTestWord(from: $0) }
        pool.append(contentsOf: reviewWords)
        
        // 5. Get 0-1 mastered words (0-5%) - optional confidence boost
        let masteredWordsForPool = wordStateManager.getWordsByState(.mastered)
            .filter { isAvailable(stateData: $0, minCooldown: 300) } // 5 min cooldown
            .shuffled()
            .prefix(1)
            .compactMap { getTestWord(from: $0) }
        pool.append(contentsOf: masteredWordsForPool)
        
        // If we don't have enough words, fill with available words from any state (except mastered if possible)
        if pool.count < 20 {
            let poolKeys = Set(pool.map { wordKey(swedish: $0.swedish, english: $0.english) })
            let allStateWordsForPool = wordStateManager.getAllWordStates()
                .filter { stateData in
                    let key = wordKey(swedish: stateData.swedish, english: stateData.english)
                    return !poolKeys.contains(key) && stateData.state != .mastered
                }
                .shuffled()
                .prefix(20 - pool.count)
                .compactMap { getTestWord(from: $0) }
            pool.append(contentsOf: allStateWordsForPool)
        }
        
        // If still not enough, allow mastered words
        if pool.count < 20 {
            let poolKeys = Set(pool.map { wordKey(swedish: $0.swedish, english: $0.english) })
            let masteredForPool = wordStateManager.getWordsByState(.mastered)
                .filter { stateData in
                    let key = wordKey(swedish: stateData.swedish, english: stateData.english)
                    return !poolKeys.contains(key) && isAvailable(stateData: stateData, minCooldown: 300)
                }
                .shuffled()
                .prefix(20 - pool.count)
                .compactMap { getTestWord(from: $0) }
            pool.append(contentsOf: masteredForPool)
        }
        
        // Final fallback: any available words
        if pool.count < 20 {
            let poolKeys = Set(pool.map { wordKey(swedish: $0.swedish, english: $0.english) })
            let remainingWords = allWords
                .filter { word in
                    let key = wordKey(swedish: word.swedish, english: word.english)
                    return !poolKeys.contains(key)
                }
                .shuffled()
                .prefix(20 - pool.count)
            pool.append(contentsOf: remainingWords)
        }
        
        // Shuffle the final pool
        sessionWordPool = pool.shuffled()
        
        print("✅ Built session pool with \(sessionWordPool.count) words")
    }
    
    private func generateOptions(for word: TestWord) {
        // Get 2 random incorrect words
        let allWords = testDataManager.getRandomWords(count: 100)
        var incorrectOptions: [String] = []
        var usedAnswers: Set<String> = [word.english.lowercased()]
        
        for testWord in allWords {
            let english = testWord.english
            let englishLower = english.lowercased()
            
            // Skip if it's the correct answer or already used
            if !usedAnswers.contains(englishLower) {
                incorrectOptions.append(english)
                usedAnswers.insert(englishLower)
                if incorrectOptions.count >= 2 {
                    break
                }
            }
        }
        
        // Combine correct answer with incorrect options and shuffle
        var allOptions = [word.english] + incorrectOptions
        allOptions.shuffle()
        
        options = allOptions
    }
    
    private func checkAnswer(selected: String) {
        isCorrect = selected.lowercased() == correctAnswer.lowercased()
        showFeedback = true
        
        // Update session statistics
        sessionQuestions += 1
        if isCorrect {
            sessionCorrect += 1
        } else {
            sessionWrong += 1
        }
        
        // Track word state, per-question summary, and wrong answers
        if let word = currentWord {
            // Record answer in WordStateManager
            wordStateManager.recordAnswer(swedish: word.swedish, english: word.english, isCorrect: isCorrect)
            
            // Append per-question summary for history details
            let summary = PracticeQuestionSummary(
                swedish: word.swedish,
                english: word.english,
                isCorrect: isCorrect
            )
            sessionQuestionDetails.append(summary)
            
            // Also maintain backward compatibility with WrongAnswersManager
            if !isCorrect {
                // Add to wrong answers list
                wrongAnswersManager.addWrongAnswer(swedish: word.swedish, english: word.english)
            } else {
                // If this word was in wrong answers, record the correct answer
                wrongAnswersManager.recordCorrectAnswer(swedish: word.swedish, english: word.english)
                
                // If this word came from wrong answers list and was answered correctly, remove it
                if isFromWrongAnswers {
                    wrongAnswersManager.removeWrongAnswer(swedish: word.swedish, english: word.english)
                }
            }
        }
        
        // Save progress after answering
        savePracticeProgress()
        
        // Auto-close session after 20 questions
        if sessionQuestions >= 20 {
            // Delay slightly to show feedback, then show summary
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
        // Save to history only if session is completed (exactly 20 questions)
        if sessionQuestions == 20 {
            let historyItem = PracticeHistoryItem(
                dateTaken: Date(),
                questions: sessionQuestions,
                correct: sessionCorrect,
                wrong: sessionWrong,
                successPercentage: successPercentage,
                questionsDetail: sessionQuestionDetails
            )
            practiceHistoryManager.addHistoryItem(historyItem)
        }
        
        // Reset to default screen and clear progress
        clearPracticeProgress()
        sessionQuestionDetails = []
        currentWord = nil
        selectedAnswer = nil
        showFeedback = false
        isCorrect = false
        showWhy = false
        exampleLanguage = "sv"
        questionCount = 0
        isFromWrongAnswers = false
        options = []
        correctAnswer = ""
        animatedOptionIndex = nil
        visibleLetterCount = 0
        showAudioButton = false
        showUpIcon = false
        shownWordsInSession = [] // Reset shown words when starting a new practice session
        // Reset session statistics
        sessionQuestions = 0
        sessionCorrect = 0
        sessionWrong = 0
        sessionQuestionDetails = []
        audioManager.cleanupAudio()
    }
    
    private func nextWord() {
        // Don't load a new word if we've reached 20 questions
        // The session summary will be shown automatically
        if sessionQuestions >= 20 {
            return
        }
        loadRandomWord()
        savePracticeProgress()
    }
    
    private func animateWordAppearance() {
        // Reset visible letter count to 0 and hide audio button and up icon
        visibleLetterCount = 0
        showAudioButton = false
        showUpIcon = false
        
        guard let word = currentWord else { return }
        let totalLetters = word.swedish.count
        
        // Animate each letter appearing with a delay
        for index in 0..<totalLetters {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLetterCount = index + 1
                }
            }
        }
        
        // Show audio button and up icon after all letters have appeared
        let totalAnimationTime = Double(totalLetters) * 0.05 + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationTime) {
            withAnimation(.easeIn(duration: 0.3)) {
                showAudioButton = true
                showUpIcon = true
            }
        }
    }
    
    @ViewBuilder
    private func letterByLetterText(_ text: String) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .opacity(index < visibleLetterCount ? 1.0 : 0.0)
            }
        }
    }
    
    private func savePracticeProgress() {
        guard let word = currentWord else {
            // If no current word, clear any saved progress
            clearPracticeProgress()
            return
        }
        
        let progressData = PracticeProgressData(
            wordId: word.id,
            swedish: word.swedish,
            english: word.english,
            correctAnswer: correctAnswer,
            options: options,
            selectedAnswer: selectedAnswer ?? "",
            showFeedback: showFeedback,
            isCorrect: isCorrect,
            questionCount: questionCount,
            isFromWrongAnswers: isFromWrongAnswers,
            showWhy: showWhy,
            exampleLanguage: exampleLanguage
        )
        
        do {
            let encoded = try JSONEncoder().encode(progressData)
            UserDefaults.standard.set(encoded, forKey: practiceProgressKey)
        } catch {
            print("❌ Failed to save practice progress: \(error)")
        }
    }
    
    private func loadPracticeProgress() {
        guard let data = UserDefaults.standard.data(forKey: practiceProgressKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(PracticeProgressData.self, from: data)
            
            // Try to find the original word from TestDataManager
            if let originalWord = testDataManager.getWordsByContent(swedish: decoded.swedish, english: decoded.english) {
                currentWord = originalWord
            } else {
                // Fallback: create word without example if not found
                currentWord = TestWord(swedish: decoded.swedish, english: decoded.english)
            }
            
            // Restore state
            correctAnswer = decoded.correctAnswer
            options = decoded.options
            selectedAnswer = decoded.selectedAnswer.isEmpty ? nil : decoded.selectedAnswer
            showFeedback = decoded.showFeedback
            isCorrect = decoded.isCorrect
            questionCount = decoded.questionCount
            isFromWrongAnswers = decoded.isFromWrongAnswers
            showWhy = decoded.showWhy
            exampleLanguage = decoded.exampleLanguage
            
            // Note: Session statistics are not restored - they're per-session only
            // They will be recalculated as user continues
            
            // Generate audio for the restored word
            if let word = currentWord {
                audioManager.generateAudio(for: word.swedish)
            }
        } catch {
            print("❌ Failed to load practice progress: \(error)")
            clearPracticeProgress()
        }
    }
    
    private func clearPracticeProgress() {
        UserDefaults.standard.removeObject(forKey: practiceProgressKey)
    }
    
    // Calculate optimal font size for Swedish word to ensure it fits
    private func calculateOptimalFontSize(for text: String, availableWidth: CGFloat) {
        // Account for button width (40) + spacing (12) + horizontal padding (40 total)
        let buttonAndSpacing: CGFloat = 40 + 12
        let actualAvailableWidth = availableWidth - buttonAndSpacing
        
        // For words longer than 9 letters, start with a smaller default size
        let isLongWord = text.count > 9
        let startingSize: CGFloat = isLongWord ? 36 : 48
        let minSize: CGFloat = 20
        let maxSize: CGFloat = isLongWord ? 36 : 48
        
        // Measure text width at starting size
        let textWidth = measureTextWidth(text: text, fontSize: startingSize)
        
        // If text fits at starting size, use it
        if textWidth <= actualAvailableWidth {
            swedishWordFontSize = startingSize
            return
        }
        
        // Binary search for optimal font size
        var currentMinSize = minSize
        var currentMaxSize = maxSize
        var optimalSize: CGFloat = startingSize
        
        while currentMinSize <= currentMaxSize {
            let midSize = (currentMinSize + currentMaxSize) / 2
            let widthAtMidSize = measureTextWidth(text: text, fontSize: midSize)
            
            if widthAtMidSize <= actualAvailableWidth {
                optimalSize = midSize
                currentMinSize = midSize + 0.5 // Try larger size (smaller increment for precision)
            } else {
                currentMaxSize = midSize - 0.5 // Try smaller size
            }
        }
        
        // Ensure we never exceed available width (add small margin for safety)
        let finalWidth = measureTextWidth(text: text, fontSize: optimalSize)
        if finalWidth > actualAvailableWidth - 2 {
            // Reduce size slightly if still too wide
            optimalSize = max(minSize, optimalSize - 1)
        }
        
        swedishWordFontSize = optimalSize
    }
    
    // Measure text width at given font size
    private func measureTextWidth(text: String, fontSize: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width
    }
    
    // Helper function to make the specific word bold in the sentence
    private func makeBoldWordSentence(text: String, wordToBold: String) -> Text {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use AttributedString for iOS 26+ compatibility (replaces deprecated Text + operator)
        var attributedString = AttributedString(trimmedText)
        
        // Find all occurrences of the word (case-insensitive) in the original string
        var searchRange = trimmedText.startIndex..<trimmedText.endIndex
        var ranges: [Range<AttributedString.Index>] = []
        
        while let stringRange = trimmedText.range(of: wordToBold, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
            // Convert String range to AttributedString range
            if let attrRange = Range(stringRange, in: attributedString) {
                ranges.append(attrRange)
            }
            
            // Continue searching after this occurrence
            if stringRange.upperBound < trimmedText.endIndex {
                searchRange = stringRange.upperBound..<trimmedText.endIndex
            } else {
                break
            }
        }
        
        // Apply bold formatting to all found ranges
        for range in ranges {
            attributedString[range].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        }
        
        return Text(attributedString)
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let isDisabled: Bool
    let isAnimating: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Centered text
                Text(text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(buttonTextColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                // Icon on the right
                HStack {
                    Spacer()
                    Group {
                        if isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        } else if isIncorrect {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        } else {
                            // Invisible placeholder to maintain consistent width
                            Color.clear
                                .frame(width: 18, height: 18)
                        }
                    }
                }
                .padding(.trailing, 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
//            .shadow(color: isCorrect || isIncorrect ? .clear : Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
            return Color(.green) // medium green border (#90ee90 style)
        } else if isIncorrect {
            return Color(.red)   // medium red border
        } else {
            return Color.gray.opacity(0.6) // gray thin border for the third (neutral) option
        }
    }
    
    private var buttonTextColor: Color {
        if isCorrect || isIncorrect {
            return .primary
        } else {
            return .primary
        }
    }
}

struct MyListButton: View {
    let word: TestWord
    @StateObject private var myListManager = MyListManager.shared
    @State private var isInMyList: Bool = false
    
    var body: some View {
        Button(action: {
            if isInMyList {
                myListManager.removeFromMyList(swedish: word.swedish, english: word.english)
            } else {
                myListManager.addToMyList(swedish: word.swedish, english: word.english)
            }
            isInMyList = myListManager.isInMyList(swedish: word.swedish, english: word.english)
        }) {
            Image("My list")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(isInMyList ? .green : .gray)
        }
        .onAppear {
            isInMyList = myListManager.isInMyList(swedish: word.swedish, english: word.english)
        }
        .onChange(of: word.swedish) { _, _ in
            isInMyList = myListManager.isInMyList(swedish: word.swedish, english: word.english)
        }
    }
}

struct PracticeSummaryModal: View {
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
                
                // Motivational message
                Text(motivationalMessage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Pie chart
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 30)
                        .frame(width: 200, height: 200)
                    
                    // Correct answers arc
                    Circle()
                        .trim(from: 0, to: correctRatio)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    // Wrong answers arc
                    if wrongRatio > 0 {
                        Circle()
                            .trim(from: correctRatio, to: correctRatio + wrongRatio)
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // Center percentage
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
                
                // Statistics
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        // Questions
                        VStack(spacing: 8) {
                            Text("\(questions)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Questions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // Correct
                        VStack(spacing: 8) {
                            Text("\(correct)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                            Text("Correct")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // Wrong
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
                    Button("Done") {
                        dismiss()
                        // onDismiss will be called by the sheet's onDismiss modifier
                    }
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

struct LastSessionPieChart: View {
    /// `nil` shows 0% and "—" for date (no completed 20-question session yet).
    let practiceItem: PracticeHistoryItem?
    @State private var animatedCorrectRatio: Double = 0
    @State private var animatedWrongRatio: Double = 0
    @State private var animatedPercentage: Int = 0
    @State private var chartScale: CGFloat = 0.8
    @State private var chartOpacity: Double = 0
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
    
    private var correctRatio: Double {
        guard let p = practiceItem, p.questions > 0 else { return 0 }
        return Double(p.correct) / Double(p.questions)
    }
    
    private var wrongRatio: Double {
        guard let p = practiceItem, p.questions > 0 else { return 0 }
        return Double(p.wrong) / Double(p.questions)
    }
    
    private var successPercentage: Int {
        practiceItem?.successPercentage ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Title with date
            Text(practiceItem == nil ? "No test information yet" : "Your last practice \(practiceItem.map { dateFormatter.string(from: $0.dateTaken) } ?? "—")")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // Pie chart
            Spacer()
                .frame(height: 16)
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 20)
                    .frame(width: 140, height: 140)
                
                // Correct answers arc
                Circle()
                    .trim(from: 0, to: animatedCorrectRatio)
                    .stroke(Color(red: 0.4, green: 0.8, blue: 0.4), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                
                // Wrong answers arc
                if wrongRatio > 0 {
                    Circle()
                        .trim(from: animatedCorrectRatio, to: animatedCorrectRatio + animatedWrongRatio)
                        .stroke(Color(red: 1.0, green: 0.5, blue: 0.5), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }
                
                // Center percentage
                VStack(spacing: 4) {
                    Text("\(animatedPercentage)%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Success")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .scaleEffect(chartScale)
            .opacity(chartOpacity)
        }
        .padding(.vertical, 20)
        .onAppear {
            // Animate chart appearance
            withAnimation(.easeOut(duration: 0.5)) {
                chartScale = 1.0
                chartOpacity = 1.0
            }
            
            // Animate arcs drawing
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animatedCorrectRatio = correctRatio
            }
            
            if wrongRatio > 0 {
                withAnimation(.easeInOut(duration: 0.8).delay(0.6)) {
                    animatedWrongRatio = wrongRatio
                }
            }
            
            // Animate percentage counting
            let steps = 20
            let stepDuration = 0.8 / Double(steps)
            for i in 0...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + (stepDuration * Double(i))) {
                    withAnimation(.linear(duration: stepDuration)) {
                        animatedPercentage = Int((Double(i) / Double(steps)) * Double(successPercentage))
                    }
                }
            }
        }
    }
}

#Preview {
    PracticeView()
}
