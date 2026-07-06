//
//  WorderHistoryView.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-02-01.
//

import SwiftUI

struct WorderHistoryView: View {
    @StateObject private var practiceHistoryManager = WorderPracticeHistoryManager.shared
    @State private var selectedFilter: WorderFilterOption = .all
    @State private var showItems: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    // Detail / retake states
    @State private var selectedItem: WordOrderHistoryItem? = nil
    @State private var retakeExampleIds: [Int] = []
    @State private var retakeExampleOrder: [Int] = []
    @State private var retakeSessionType: WorderHistorySessionType = .wordOrder
    // Identity-bound retake session to ensure sheet receives fresh data
    @State private var retakeSession: RetakeSession? = nil

    private struct RetakeSession: Identifiable {
        let id = UUID()
        let exampleIds: [Int]
        let exampleOrder: [Int]
        let sessionType: WorderHistorySessionType
    }
    
    enum WorderFilterOption: String, CaseIterable {
        case all = "All"
        case wordOrder = "Practices"
        case test = "Tests"
    }

    // Allow initializing the view with a starting filter (e.g. show only Word Order history)
    init(initialFilter: WorderFilterOption? = nil) {
        _selectedFilter = State(initialValue: initialFilter ?? .all)
    }
    
    private var allHistoryItems: [WordOrderHistoryItem] {
        let items = practiceHistoryManager.historyItems
        switch selectedFilter {
        case .all:
            return items.sorted { $0.dateTaken > $1.dateTaken }
        case .wordOrder:
            return items.filter { $0.effectiveType == .wordOrder }.sorted { $0.dateTaken > $1.dateTaken }
        case .test:
            return items.filter { $0.effectiveType == .test }.sorted { $0.dateTaken > $1.dateTaken }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - same design as Worder practice title
            ZStack {
                HStack {
                    Spacer()
                    SplitTitleView("History", splitIndex: 4)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(WorderFilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            contentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedItem) { item in
            WorderHistoryDetailModal(item: item) { ids, order, sessionType in
                // Start retake flow with the selected example IDs, order, and session type
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    retakeSession = RetakeSession(exampleIds: ids, exampleOrder: order, sessionType: sessionType)
                }
            }
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        .sheet(item: $retakeSession) { session in
            RetakeModalHost(session: session)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
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
                .lineLimit(4)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 20)
        .padding(.horizontal)
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "Complete a practice session to see your results here"
        case .wordOrder:
            return "Complete a Word Order practice session to see your results here"
        case .test:
            return "Complete a Test session to see your results here"
        }
    }
    
    private var resultsListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(allHistoryItems.enumerated()), id: \.element.id) { index, item in
                    WorderHistoryResultRow(item: item, showTypeLabel: selectedFilter == .all)
                        .onTapGesture {
                            selectedItem = item
                        }
                        .scaleEffect(showItems ? 1 : 0.5)
                        .opacity(showItems ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75)
                                .delay(showItems ? Double(index) * 0.08 : Double(allHistoryItems.count - 1 - index) * 0.08),
                            value: showItems
                        )
                }
            }
            .padding(.vertical, 20) 
            .padding(.bottom, 55)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            showItems = true
        }
    }
    
    // Host view that runs a retake session in a modal, shows summary, then saves history and dismisses
    private struct RetakeModalHost: View {
        let session: RetakeSession
        @Environment(\.dismiss) private var dismiss
        @State private var summaryItem: RetakeSummary? = nil

        private struct RetakeSummary: Identifiable {
            let id = UUID()
            let questions: Int
            let correct: Int
            let results: [WorderQuestionResult]
            let successPercentage: Int
            let motivationalMessage: String
        }
        @State private var pendingSave: RetakeSummary? = nil

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
                    initialExampleIds: session.exampleIds,
                    onSessionComplete: { questions, correct, results in
                        let percentage = questions > 0 ? Int((Double(correct) / Double(questions)) * 100) : 0
                        DispatchQueue.main.async {
                            let s = RetakeSummary(
                                questions: questions,
                                correct: correct,
                                results: results,
                                successPercentage: percentage,
                                motivationalMessage: motivationalMessage(for: percentage)
                            )
                            summaryItem = s
                            pendingSave = s
                            NotificationCenter.default.post(name: .worderResetSession, object: nil)
                        }
                    },
                    initialExampleOrder: session.exampleOrder,
                    customTitle: session.sessionType == .test ? "Test" : "Practice",
                    sessionLimit: max(session.exampleIds.count, session.exampleOrder.count, 1),
                    sessionType: session.sessionType
                )
            }
            .sheet(item: $summaryItem, onDismiss: {
                if let save = pendingSave {
                    WorderPracticeHistoryManager.shared.addSession(
                        questions: save.questions,
                        correct: save.correct,
                        exampleIDs: session.exampleIds,
                        questionResults: save.results,
                        sessionType: session.sessionType,
                        insertAtTop: true
                    )
                    pendingSave = nil
                }
                dismiss()
            }) { item in
                WorderSummaryModal(
                    questions: item.questions,
                    correct: item.correct,
                    wrong: max(0, item.questions - item.correct),
                    successPercentage: item.successPercentage,
                    motivationalMessage: item.motivationalMessage
                )
            }
        }
    }
}

// MARK: - History Detail Modal (shows sentences and allows retake)
struct WorderHistoryDetailModal: View {
    let item: WordOrderHistoryItem
    let onRetake: (_ exampleIDs: [Int], _ order: [Int], _ sessionType: WorderHistorySessionType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExampleForInfo: WordOrderExample? = nil

    private var examples: [WordOrderExample] {
        guard let ids = item.exampleIDs, !ids.isEmpty else { return [] }
        let all = WordOrderDataManager.shared.getAllExamples()
        return ids.compactMap { id in all.first(where: { $0.id == id }) }
    }

    /// Returns examples paired with optional correctness (true = correct, false = wrong, nil = unknown)
    private var detailedExamples: [(example: WordOrderExample, correct: Bool?)] {
        let all = WordOrderDataManager.shared.getAllExamples()
        if let results = item.questionResults, !results.isEmpty {
            return results.compactMap { res in
                guard let ex = all.first(where: { $0.id == res.exampleID }) else { return nil }
                return (example: ex, correct: res.correct)
            }
        } else if let ids = item.exampleIDs {
            return ids.compactMap { id in
                guard let ex = all.first(where: { $0.id == id }) else { return nil }
                return (example: ex, correct: nil)
            }
        } else {
            return []
        }
    }
    
    private struct DetailedExample: Identifiable {
        let id: Int
        let example: WordOrderExample
        let correct: Bool?
        let userAnswer: String?
    }

    private struct DetailedExampleRow: View {
        let index: Int
        let example: WordOrderExample
        let correct: Bool?
        let userAnswer: String?
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(index).")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                    Text(example.answer.singleSpaced)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(correct == nil ? .primary : (correct! ? .green : .red))
                }
                if let ua = userAnswer, !ua.isEmpty {
                    Text("You: \(ua)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.leading, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        }
    }

    private var detailedExamplesList: [DetailedExample] {
        let all = WordOrderDataManager.shared.getAllExamples()
        if let results = item.questionResults, !results.isEmpty {
            return results.compactMap { res in
                guard let ex = all.first(where: { $0.id == res.exampleID }) else { return nil }
                let normalizedUser = normalizeAnswer(res.userAnswer)
                let normalizedCorrect = normalizeAnswer(ex.answer)
                let computedCorrect = normalizedUser == normalizedCorrect
                return DetailedExample(id: ex.id, example: ex, correct: computedCorrect, userAnswer: res.userAnswer)
            }
        } else if let ids = item.exampleIDs {
            return ids.compactMap { id in
                guard let ex = all.first(where: { $0.id == id }) else { return nil }
                return DetailedExample(id: ex.id, example: ex, correct: nil, userAnswer: nil)
            }
        } else {
            return []
        }
    }

    private func normalizeAnswer(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let components = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        return f
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: {
                        let order: [Int]
                        if let results = item.questionResults, !results.isEmpty {
                            order = results.map { $0.exampleID }
                        } else if let ids = item.exampleIDs, !ids.isEmpty {
                            order = ids
                        } else {
                            order = []
                        }
                        onRetake(item.exampleIDs ?? [], order, item.effectiveType)
                        dismiss()
                    }) {
                        Text("Retake")
                            .font(.body)
                            .foregroundColor(.appRed)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.body)
                            .foregroundColor(.appRed)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)

                HStack {
                    Spacer()
                    Text("Details")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 20)
            .padding(.bottom, 8)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dateFormatter.string(from: item.dateTaken))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
                Spacer()
                let computedCorrect = detailedExamplesList.compactMap({ $0.correct }).filter({ $0 }).count
                let computedPercentage = item.questions > 0 ? Int((Double(computedCorrect) / Double(item.questions)) * 100) : item.percentage
                Text("\(computedPercentage)%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            .padding(.top, 20)
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if detailedExamples.isEmpty {
                        Text("No sentence data available for this session.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    } else {
                        ForEach(Array(detailedExamplesList.enumerated()), id: \.element.id) { index, pair in
                            DetailedExampleRow(index: index + 1, example: pair.example, correct: pair.correct, userAnswer: pair.userAnswer)
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                    selectedExampleForInfo = pair.example
                                }
                        }
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .interactiveDismissDisabled()
        .sheet(item: $selectedExampleForInfo) { example in
            ExampleDetailModal(example: example)
        }
    }

    private struct ExampleDetailModal: View {
        let example: WordOrderExample
        @Environment(\.dismiss) private var dismiss
        @Environment(\.colorScheme) var colorScheme
        @StateObject private var myListManager = WorderMyListManager.shared
        var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            if myListManager.isInMyList(swedish: example.answer, english: example.answerTranslation) {
                                myListManager.removeFromMyList(swedish: example.answer, english: example.answerTranslation)
                            } else {
                                myListManager.addToMyList(swedish: example.answer, english: example.answerTranslation)
                            }
                        }) {
                            MyListFavoriteIcon(
                                isInList: myListManager.isInMyList(
                                    swedish: example.answer,
                                    english: example.answerTranslation
                                )
                            )
                            .padding(.top, 20)
                            .padding(.leading, 10)
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Text("Close")
                                .font(.body)
                                .foregroundColor(.appRed)
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 10)
                    }
                    .padding(.horizontal, 20)
                    ZStack {
                        HStack {
                            Spacer()
                            Text("More info")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.bottom, 30)
                            Spacer()
                        }
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 10)

                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 50) {
                                Rectangle()
                                    .fill(Color(.separator))
                                    .frame(height: 5)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 0)
                                    .padding(.top, 20)

                                VStack(spacing: 16) {
                                    let swedishTokens = example.answer.singleSpaced.split(separator: " ").map { String($0) }

                                    FlowLayout(spacing: 6) {
                                        ForEach(Array(swedishTokens.enumerated()), id: \.0) { idx, token in
                                            VStack(spacing: 4) {
                                                Text("\(idx + 1)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.black)
                                                    .frame(width: 20, height: 20)
                                                    .background(Circle().fill(Color.clear))
                                                    .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                                    .multilineTextAlignment(.center)

                                                Text(token)
                                                    .font(.system(size: 28, weight: .bold))
                                                    .foregroundColor(.appRed)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .padding(.horizontal, 2)
                                            .padding(.vertical, 2)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)

                                    Text(example.answerTranslation.singleSpaced)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)

                                Rectangle()
                                    .fill(Color(.separator))
                                    .frame(height: 5)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 0)

                                if let tip = example.tip, !tip.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("Why?")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        Text(tip)
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 20)
                                }

                                Button(action: { dismiss() }) {
                                    Text("Got it")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.appRed)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 30)

                                Spacer()
                                    .frame(height: geometry.size.height * 0.1)
                            }
                            .frame(minHeight: geometry.size.height)
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct WorderHistoryResultRow: View {
    let item: WordOrderHistoryItem
    var showTypeLabel: Bool = true
    @Environment(\.colorScheme) var colorScheme
    
    private var isLargePhone: Bool {
        if let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = screen.windows.first {
            return window.bounds.width >= 430
        }
        return UIScreen.main.bounds.width >= 430
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        return formatter
    }
    
    private var typeLabel: String {
        switch item.effectiveType {
        case .wordOrder: return "Practice"
        case .test: return "Test"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if showTypeLabel {
                            Text(typeLabel)
                                .font(.system(size: isLargePhone ? 20 : 18))
                                .fontWeight(.medium)
                                .foregroundColor(.appRed)
                            Text("•")
                                .foregroundColor(.secondary)
                        }
                        Text(dateFormatter.string(from: item.dateTaken))
                            .font(.system(size: isLargePhone ? 20 : 18))
                            .fontWeight(.medium)
                    }
                }
                Spacer()
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            
            makeStyledPracticeText(
                questions: item.questions,
                correct: item.correct,
                wrong: item.wrong,
                percentage: item.percentage
            )
            .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
    }
    
    private func makeStyledPracticeText(questions: Int, correct: Int, wrong: Int, percentage: Int) -> Text {
        var attributedString = AttributedString("Questions: \(questions)")
        attributedString.font = (.system(size: isLargePhone ? 15 : 13, weight: .bold))
        attributedString.foregroundColor = .primary
        
        var dash1 = AttributedString(" - ")
        dash1.font = (.system(size: isLargePhone ? 15 : 13, weight: .bold))
        dash1.foregroundColor = .primary
        attributedString.append(dash1)
        
        var correctAttr = AttributedString("Correct: \(correct)")
        correctAttr.font = (.system(size: isLargePhone ? 15 : 13, weight: .bold))
        correctAttr.foregroundColor = .green
        attributedString.append(correctAttr)
        
        var dash2 = AttributedString(" - ")
        dash2.font = (.system(size: isLargePhone ? 15 : 13, weight: .bold))
        dash2.foregroundColor = .primary
        attributedString.append(dash2)
        
        var wrongAttr = AttributedString("Wrong: \(wrong)")
        wrongAttr.font = (.system(size: isLargePhone ? 15 : 13, weight: .bold))
        wrongAttr.foregroundColor = .red
        attributedString.append(wrongAttr)
        
        var dash3 = AttributedString(" - ")
        dash3.font = (.system(size: isLargePhone ? 15 : 13, weight: .bold))
        dash3.foregroundColor = .primary
        attributedString.append(dash3)
        
        var percentageAttr = AttributedString("\(percentage)%")
        percentageAttr.font = (.system(size: isLargePhone ? 15 : 13, weight: .bold))
        percentageAttr.foregroundColor = .primary
        attributedString.append(percentageAttr)
        
        return Text(attributedString)
    }
}

#Preview {
    WorderHistoryView()
}

// Helper: normalize whitespace to single spaces for display
private extension String {
    var singleSpaced: String {
        let pattern = "\\s+"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(self.startIndex..., in: self)
            let replaced = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: " ")
            return replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
