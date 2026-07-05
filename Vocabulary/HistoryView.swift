import SwiftUI

struct HistoryView: View {
    @StateObject private var testHistoryManager = TestHistoryManager.shared
    @StateObject private var practiceHistoryManager = PracticeHistoryManager.shared
    @StateObject private var grammarResultsManager = TestResultsManager()
    @StateObject private var adjectivesPracticeManager = AdjectivesPracticeHistoryManager.shared
    @StateObject private var worderHistoryManager = WorderPracticeHistoryManager.shared
    @State private var selectedItem: UnifiedHistoryItem?
    @State private var selectedFilter: FilterOption = .all
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // Optional filter to show only test or practice items (used when opened from other views)
    var filterType: HistoryItemType? = nil
    
    /// When true, used as the main app tab (reduces top padding; no Close button).
    var useAsMainTab: Bool = false
    
    /// When non-nil, main-tab History applies this filter once on appear (e.g. from Vocabulary Practice "Previous practices").
    @Binding var initialFilter: FilterOption?
    
    init(filterType: HistoryItemType? = nil, useAsMainTab: Bool = false, initialFilter: Binding<FilterOption?> = .constant(nil), onSelectTest: ((TestHistoryItem) -> Void)? = nil, onSelectPractice: ((PracticeHistoryItem) -> Void)? = nil) {
        self.filterType = filterType
        self.useAsMainTab = useAsMainTab
        self._initialFilter = initialFilter
        self.onSelectTest = onSelectTest
        self.onSelectPractice = onSelectPractice
    }
    
    // Callbacks when an item is selected (used when History is the main tab to switch and load)
    var onSelectTest: ((TestHistoryItem) -> Void)? = nil
    var onSelectPractice: ((PracticeHistoryItem) -> Void)? = nil
    
    /// Filter options by app topic when History is used as the main tab.
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case vocabulary = "Vocabulary"
        case grammar = "Grammar"
        case adjectives = "Adjectives"
        case worder = "Word Order"
    }
    
    private var allHistoryItems: [UnifiedHistoryItem] {
        var items: [UnifiedHistoryItem] = []
        
        // Determine which question-type items to include (tests/practices) based on filterType parameter.
        // When filterType is nil (main History tab), we include both tests and practices.
        let typeFilter: HistoryItemType? = filterType
        
        // Add test items (only if no filter or filter is .test)
        if typeFilter == nil || typeFilter == .test {
            items.append(contentsOf: testHistoryManager.historyItems.map { UnifiedHistoryItem(testItem: $0) })
            // Add grammar test results (Grammar Pronouns, Grammar Reflexiva, etc.)
            items.append(contentsOf: grammarResultsManager.results.map { UnifiedHistoryItem(grammarResult: $0) })
            // Add worder test sessions
            items.append(contentsOf: worderHistoryManager.historyItems.filter { $0.effectiveType == .test }.map { UnifiedHistoryItem(worderItem: $0) })
        }
        
        // Add practice items (only if no filter or filter is .practice)
        if typeFilter == nil || typeFilter == .practice {
            items.append(contentsOf: practiceHistoryManager.historyItems.map { UnifiedHistoryItem(practiceItem: $0) })
            // Add adjective practice results (Adjective Antonyms, Agreement, Comparison)
            items.append(contentsOf: adjectivesPracticeManager.historyItems.map { UnifiedHistoryItem(adjectivesPracticeItem: $0) })
            // Add worder practice sessions
            items.append(contentsOf: worderHistoryManager.historyItems.filter { $0.effectiveType == .wordOrder }.map { UnifiedHistoryItem(worderItem: $0) })
        }
        
        // Sort by date (most recent first)
        let sorted = items.sorted { $0.dateTaken > $1.dateTaken }
        
        // When opened with a specific filterType (from another view), do not apply topic filters.
        guard filterType == nil else { return sorted }
        
        // Apply topic filter (Vocabulary / Grammar / Adjectives / Worder) when History is the main tab.
        switch selectedFilter {
        case .all:
            return sorted
        case .vocabulary:
            return sorted.filter { $0.testItem != nil || $0.practiceItem != nil }
        case .grammar:
            return sorted.filter { $0.grammarResult != nil }
        case .adjectives:
            return sorted.filter { $0.adjectivesPracticeItem != nil }
        case .worder:
            return sorted.filter { $0.worderItem != nil }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title - matching TestView and PracticeView style
            ZStack {
                // Centered title - separate for each case with individual padding control
                if filterType == .practice {
                    HStack {
                        Spacer()
                        SplitTitleView("Practice History", splitIndex: 8)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                } else if filterType == .test {
                    HStack {
                        Spacer()
                        SplitTitleView("Test History", splitIndex: 4)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                } else {
                    HStack {
                        Spacer()
                        SplitTitleView("History", splitIndex: 4)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, useAsMainTab ? 8 : 65)  // Small extra padding when tab; top safe area is respected
                    .padding(.bottom, 20)
                }
                
                // Close button - aligned to right (only show when used as modal, i.e., when filterType is set)
                if filterType != nil {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Close")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }
            }
            
            // Filter controls (show when filterType is nil, even if there are no history items)
            if filterType == nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedFilter = option
                            }) {
                                Text(option.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedFilter == option ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(selectedFilter == option ? Color.appRed : Color(.systemGray5))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
                .padding(.top, 10)
            }
            
            // Content
            contentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: useAsMainTab ? .bottom : .all)  // When tab, respect top safe area so title is visible
        .onAppear {
            if filterType == nil, let filter = initialFilter {
                selectedFilter = filter
                initialFilter = nil
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if allHistoryItems.isEmpty {
            emptyStateView
        } else {
            resultsListView
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No History Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 20)
        .padding(.bottom, 55) // leave room for tab bar
        .padding(.horizontal, 20)
    }
    
    private var resultsListView: some View {
        List {
            ForEach(allHistoryItems) { item in
                Button(action: { selectedItem = item }) {
                    HistoryResultRow(
                        item: item,
                        isAnimating: false,
                        filterType: filterType
                    )
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                // Match previous 20pt side padding and tighten vertical spacing
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteHistoryItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedItem) { item in
            HistoryItemDetailModal(
                item: item,
                onSelectTest: onSelectTest,
                onSelectPractice: onSelectPractice,
                onDismiss: { selectedItem = nil; if filterType != nil { dismiss() } }
            )
        }
    }
    
    private var emptyStateMessage: String {
        switch filterType {
        case .test:
            return "Complete a test to see your results here"
        case .practice:
            return "Complete a practice session to see your results here"
        case .grammar:
            return "Complete a grammar practice to see your results here"
        case .adjective:
            return "Complete an adjective practice to see your results here"
        case .worder:
            return "Complete a worder practice or test to see your results here"
        case .none:
            return "Complete a test or practice session to see your results here"
        }
    }

    private func deleteHistoryItem(_ item: UnifiedHistoryItem) {
        if let testItem = item.testItem {
            testHistoryManager.deleteHistoryItem(testItem)
        } else if let practiceItem = item.practiceItem {
            practiceHistoryManager.deleteHistoryItem(practiceItem)
        } else if let grammarResult = item.grammarResult {
            grammarResultsManager.deleteResult(grammarResult)
        } else if let adjectivesItem = item.adjectivesPracticeItem {
            adjectivesPracticeManager.deleteHistoryItem(adjectivesItem)
        } else if let worderItem = item.worderItem {
            worderHistoryManager.deleteHistoryItem(worderItem)
        }
    }
}

struct HistoryResultRow: View {
    let item: UnifiedHistoryItem
    let isAnimating: Bool
    let filterType: HistoryItemType?
    @Environment(\.colorScheme) var colorScheme
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }

    private func colorForPercentage(_ percentage: Int) -> Color {
        switch percentage {
        case 0...30:
            return .red
        case 31...70:
            return .orange
        default:
            return .green
        }
    }
    
    var body: some View {
        let questions = item.total
        let correct = item.score
        let wrong = item.total - item.score
        let percentage = item.total > 0 ? Int((Double(item.score) / Double(item.total)) * 100) : 0

        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // First line: type title only (when not filtered to a single type)
                if filterType == nil {
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: item.topicIconSystemName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.appRed)
                            .accessibilityHidden(true)
                        Text(item.displayTitle)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.appRed)
                    }
                }

                // Second line: date before correct/wrong status
                makeStyledPracticeText(
                    date: dateFormatter.string(from: item.dateTaken),
                    correct: correct,
                    wrong: wrong
                )
                .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(percentage)%")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(colorForPercentage(percentage))
                .frame(minWidth: 56, alignment: .trailing)
                .accessibilityLabel("Success percentage")
                .accessibilityValue("\(percentage) percent")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())

        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
//        .padding(.horizontal, 20)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isAnimating)
    }
    
    // Helper function to create styled practice text with colors
    private func makeStyledPracticeText(date: String, correct: Int, wrong: Int) -> Text {
        // Match compact status format on left: "dd/MM/yyyy | ✓ 2 | × 8"
        var attributedString = AttributedString(date)
        attributedString.font = .system(size: 13, weight: .medium)
        attributedString.foregroundColor = .primary

        var dateSeparator = AttributedString(" | ")
        dateSeparator.font = .system(size: 13, weight: .semibold)
        dateSeparator.foregroundColor = .primary
        attributedString.append(dateSeparator)

        var correctAttr = AttributedString("✓ \(correct)")
        correctAttr.font = .system(size: 13, weight: .semibold)
        correctAttr.foregroundColor = .green
        attributedString.append(correctAttr)

        var separator1 = AttributedString(" | ")
        separator1.font = .system(size: 13, weight: .semibold)
        separator1.foregroundColor = .primary
        attributedString.append(separator1)

        var wrongAttr = AttributedString("× \(wrong)")
        wrongAttr.font = .system(size: 13, weight: .semibold)
        wrongAttr.foregroundColor = .red
        attributedString.append(wrongAttr)

        return Text(attributedString)
    }
}

// MARK: - Shared history detail question card (Grammar-style: number, text, subtitle, green/red)

struct HistoryDetailQuestionCard: View {
    let index: Int
    let mainText: String
    let subtitleText: String?
    let isCorrect: Bool

    init(index: Int, mainText: String, subtitleText: String? = nil, isCorrect: Bool) {
        self.index = index
        self.mainText = mainText
        self.subtitleText = subtitleText
        self.isCorrect = isCorrect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("\(index).")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(mainText)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            if let sub = subtitleText, !sub.isEmpty {
                Text(sub)
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

// MARK: - Vocabulary test history word row (same look as TestWordCard when answered)

struct VocabularyTestHistoryWordRow: View {
    let wordData: TestWordItemData
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            Text(wordData.swedish)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 2)

            HStack(spacing: 8) {
                Text(wordData.english)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Image(systemName: wordData.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(wordData.isCorrect ? .green : .red)
                    .font(.title3)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 30)
        .padding(16)
        .background(
            wordData.isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(wordData.isCorrect ? Color.green : Color.red, lineWidth: 1)
        )
    }
}

// MARK: - Vocabulary practice history word row (same design as test)

struct VocabularyPracticeHistoryWordRow: View {
    let summary: PracticeQuestionSummary
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            Text(summary.swedish)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 2)
            
            HStack(spacing: 8) {
                Text(summary.english)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Image(systemName: summary.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(summary.isCorrect ? .green : .red)
                    .font(.title3)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 30)
        .padding(16)
        .background(
            summary.isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(summary.isCorrect ? Color.green : Color.red, lineWidth: 1)
        )
    }
}

// MARK: - History Item Detail Modal (test/practice content + scoring)

struct HistoryItemDetailModal: View {
    let item: UnifiedHistoryItem
    var onSelectTest: ((TestHistoryItem) -> Void)? = nil
    var onSelectPractice: ((PracticeHistoryItem) -> Void)? = nil
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        return f
    }

    private var percentage: Int {
        item.total > 0 ? Int((Double(item.score) / Double(item.total)) * 100) : 0
    }

    private var scoreColor: Color {
        switch percentage {
        case 0...30:
            return .red
        case 31...70:
            return .orange
        default:
            return .green
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Fixed summary line (date + percentage)
                scoringSection
                    .padding(.horizontal)
                    .padding(.top)
                
                // Scrollable questions/content area
                ScrollView {
                    VStack(spacing: 24) {
                        contentSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(item.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    private var scoringSection: some View {
        HStack {
            Text(dateFormatter.string(from: item.dateTaken))
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Text("\(percentage)%")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var contentSection: some View {
        switch item.type {
        case .test:
            vocabularyTestContent
        case .practice:
            vocabularyPracticeContent
        case .grammar:
            grammarContent
        case .adjective:
            adjectiveContent
        case .worder:
            worderContent
        }
    }

    @ViewBuilder
    private var vocabularyTestContent: some View {
        if let testItem = item.testItem {
            if testItem.words.isEmpty {
                Text("No word data saved for this test")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Questions")
                        .font(.headline)
                    ForEach(testItem.words) { wordData in
                        VocabularyTestHistoryWordRow(wordData: wordData)
                    }
                }
                .padding(.top, 20)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var vocabularyPracticeContent: some View {
        if let practiceItem = item.practiceItem {
            if let details = practiceItem.questionsDetail, !details.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Questions")
                        .font(.headline)
                    ForEach(Array(details.enumerated()), id: \.element.id) { index, q in
                        VocabularyPracticeHistoryWordRow(summary: q)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("1.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Session: \(practiceItem.questions) questions, \(practiceItem.correct) correct, \(practiceItem.wrong) wrong.")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(practiceItem.successPercentage >= 60 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .cornerRadius(10)
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var grammarContent: some View {
        if let result = item.grammarResult {
            VStack(alignment: .leading, spacing: 12) {
                Text("Questions")
                    .font(.headline)
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
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var adjectiveContent: some View {
        if let practiceItem = item.adjectivesPracticeItem {
            if let details = practiceItem.questionsDetail, !details.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Questions")
                        .font(.headline)
                    ForEach(Array(details.enumerated()), id: \.element.id) { index, q in
                        let sentenceWithAnswer = q.sentence.replacingOccurrences(of: "______", with: q.answer)
                        HistoryDetailQuestionCard(
                            index: index + 1,
                            mainText: sentenceWithAnswer,
                            subtitleText: q.englishAnswer,
                            isCorrect: q.isCorrect
                        )
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("1.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Session: \(practiceItem.questions) questions, \(practiceItem.correct) correct, \(practiceItem.wrong) wrong.")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(practiceItem.successPercentage >= 60 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .cornerRadius(10)
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var worderContent: some View {
        if let worderItem = item.worderItem {
            worderQuestionsView(worderItem: worderItem)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func worderQuestionsView(worderItem: WordOrderHistoryItem) -> some View {
        let allExamples = WordOrderDataManager.shared.getAllExamples()
        if let results = worderItem.questionResults, !results.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Questions")
                    .font(.headline)
                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                    let example = allExamples.first { $0.id == result.exampleID }
                    let mainText = example?.answer ?? "Sentence \(result.exampleID)"
                    let subtitle = example?.answerTranslation
                    HistoryDetailQuestionCard(
                        index: index + 1,
                        mainText: mainText,
                        subtitleText: subtitle,
                        isCorrect: result.correct
                    )
                }
            }
        } else if let ids = worderItem.exampleIDs, !ids.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Questions")
                    .font(.headline)
                ForEach(Array(ids.enumerated()), id: \.offset) { index, exampleID in
                    let example = allExamples.first { $0.id == exampleID }
                    let mainText = example?.answer ?? "Sentence \(exampleID)"
                    HistoryDetailQuestionCard(
                        index: index + 1,
                        mainText: mainText,
                        subtitleText: example?.answerTranslation,
                        isCorrect: true
                    )
                }
            }
        } else {
            Text("No question data saved for this session")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
        }
    }

    private func labelValue(_ label: String, _ value: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }

}

#Preview {
    HistoryView()
}
