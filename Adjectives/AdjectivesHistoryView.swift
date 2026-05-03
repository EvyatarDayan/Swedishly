//
//  AdjectivesHistoryView.swift
//  Swedishly
//

import SwiftUI

enum AdjectivesHistoryItemType {
    case test
    case practice
    case adjective
    case compare
    case antonym
}

struct AdjectivesUnifiedHistoryItem: Identifiable {
    let id: UUID
    let dateTaken: Date
    let type: AdjectivesHistoryItemType
    let total: Int
    let score: Int
    let practiceType: AdjectivesPracticeType?
    
    init(testItem: AdjectivesTestHistoryItem) {
        self.id = UUID()
        self.dateTaken = testItem.dateTaken
        self.type = .test
        self.total = testItem.questions
        self.score = testItem.correct
        self.practiceType = nil
    }
    
    init(practiceItem: AdjectivesPracticeHistoryItem) {
        self.id = UUID()
        self.dateTaken = practiceItem.dateTaken
        if let practiceType = practiceItem.practiceType {
            switch practiceType {
            case .adjective: self.type = .adjective
            case .compare: self.type = .compare
            case .antonym: self.type = .antonym
            }
        } else {
            self.type = .adjective
        }
        self.total = practiceItem.questions
        self.score = practiceItem.correct
        self.practiceType = practiceItem.practiceType
    }
}

struct AdjectivesHistoryView: View {
    @StateObject private var testHistoryManager = AdjectivesTestHistoryManager.shared
    @StateObject private var practiceHistoryManager = AdjectivesPracticeHistoryManager.shared
    @State private var selectedItem: AdjectivesUnifiedHistoryItem?
    @State private var selectedFilter: AdjectivesHistoryFilterOption = .all
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var filterType: AdjectivesHistoryItemType? = nil
    
    enum AdjectivesHistoryFilterOption: String, CaseIterable {
        case all = "All"
        case adjective = "Agreement"
        case compare = "Comparison"
        case antonym = "Antonyms"
    }
    
    private var allHistoryItems: [AdjectivesUnifiedHistoryItem] {
        let activeFilter: AdjectivesHistoryFilterOption
        if let filterType = filterType {
            switch filterType {
            case .adjective: activeFilter = .adjective
            case .compare: activeFilter = .compare
            case .antonym: activeFilter = .antonym
            default: activeFilter = .all
            }
        } else {
            activeFilter = selectedFilter
        }
        
        var resultItems: [AdjectivesUnifiedHistoryItem] = []
        let allPracticeItems = practiceHistoryManager.historyItems
        
        switch activeFilter {
        case .all:
            resultItems.append(contentsOf: allPracticeItems.map { AdjectivesUnifiedHistoryItem(practiceItem: $0) })
            resultItems.append(contentsOf: testHistoryManager.historyItems.map { AdjectivesUnifiedHistoryItem(testItem: $0) })
        case .adjective:
            resultItems.append(contentsOf: allPracticeItems.filter { $0.practiceType == .adjective }.map { AdjectivesUnifiedHistoryItem(practiceItem: $0) })
        case .compare:
            resultItems.append(contentsOf: allPracticeItems.filter { $0.practiceType == .compare }.map { AdjectivesUnifiedHistoryItem(practiceItem: $0) })
        case .antonym:
            resultItems.append(contentsOf: allPracticeItems.filter { $0.practiceType == .antonym }.map { AdjectivesUnifiedHistoryItem(practiceItem: $0) })
        }
        return resultItems.sorted { $0.dateTaken > $1.dateTaken }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
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
                    .padding(.top, 65)
                    .padding(.bottom, 20)
                }
                
                if filterType != nil {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
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
            
            if filterType == nil {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(AdjectivesHistoryFilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            
            if allHistoryItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(allHistoryItems) { item in
                            Button(action: { selectedItem = item }) {
                                AdjectivesHistoryResultRow(
                                    item: item,
                                    isAnimating: false,
                                    filterType: filterType
                                )
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 55)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
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
        switch filterType {
        case .test: return "Complete a test to see your results here"
        case .practice: return "Complete a practice session to see your results here"
        case .adjective: return "Complete an Adjective practice session to see your results here"
        case .compare: return "Complete a Compare practice session to see your results here"
        case .antonym: return "Complete an Antonym practice session to see your results here"
        case .none: return "Complete a practice session to see your results here"
        }
    }
}

struct AdjectivesHistoryResultRow: View {
    let item: AdjectivesUnifiedHistoryItem
    let isAnimating: Bool
    let filterType: AdjectivesHistoryItemType?
    @Environment(\.colorScheme) var colorScheme
    
    private var isLargeScreen: Bool { UIScreen.main.bounds.width >= 430 }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 6) {
                if filterType == nil {
                    Group {
                        switch item.type {
                        case .test: Text("Test")
                        case .practice:
                            if let practiceType = item.practiceType {
                                Text(practiceType == .adjective ? "Agreement" : "Comparison")
                            } else { Text("Agreement") }
                        case .adjective: Text("Agreement")
                        case .compare: Text("Comparison")
                        case .antonym: Text("Antonyms")
                        }
                    }
                    .font(isLargeScreen ? .subheadline : .body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    Text("•")
                        .foregroundColor(.secondary)
                }
                Text(dateFormatter.string(from: item.dateTaken))
                    .font(isLargeScreen ? .subheadline : .body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            
            let questions = item.total
            let correct = item.score
            let wrong = item.total - item.score
            let percentage = item.total > 0 ? Int((Double(item.score) / Double(item.total)) * 100) : 0
            makeStyledPracticeText(questions: questions, correct: correct, wrong: wrong, percentage: percentage)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isAnimating)
    }
    
    private func makeStyledPracticeText(questions: Int, correct: Int, wrong: Int, percentage: Int) -> Text {
        var attributedString = AttributedString("Questions: \(questions)")
        attributedString.font = .system(size: 13, weight: .bold)
        attributedString.foregroundColor = .primary
        var dash1 = AttributedString(" - ")
        dash1.font = .system(size: 13, weight: .bold)
        dash1.foregroundColor = .primary
        attributedString.append(dash1)
        var correctAttr = AttributedString("Correct: \(correct)")
        correctAttr.font = .system(size: 13, weight: .bold)
        correctAttr.foregroundColor = .green
        attributedString.append(correctAttr)
        var dash2 = AttributedString(" - ")
        dash2.font = .system(size: 13, weight: .bold)
        dash2.foregroundColor = .primary
        attributedString.append(dash2)
        var wrongAttr = AttributedString("Wrong: \(wrong)")
        wrongAttr.font = .system(size: 13, weight: .bold)
        wrongAttr.foregroundColor = .red
        attributedString.append(wrongAttr)
        var dash3 = AttributedString(" - ")
        dash3.font = .system(size: 13, weight: .bold)
        dash3.foregroundColor = .primary
        attributedString.append(dash3)
        var percentageAttr = AttributedString("\(percentage)%")
        percentageAttr.font = .system(size: 13, weight: .bold)
        percentageAttr.foregroundColor = .primary
        attributedString.append(percentageAttr)
        return Text(attributedString)
    }
}

#Preview {
    AdjectivesHistoryView()
}
