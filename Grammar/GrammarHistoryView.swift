//
//  GrammarHistoryView.swift
//  SWGrammar (renamed from HistoryView.swift to avoid duplicate build output)
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

enum TestFilter: String, CaseIterable {
    case all = "All"
    case pronouns = "Pronouns"
    case gender = "Gender"
    case verbs = "Verbs"
    case reflexiva = "Reflexiva"
}

struct GrammarHistoryView: View {
    @ObservedObject var resultsManager: TestResultsManager
    @State private var selectedResult: TestResult? = nil
    @State private var animatedItemId: UUID? = nil
    @State private var selectedFilter: TestFilter = .all

    // ViewModels for retake functionality - passed from MainView
    var verbQuizViewModel: VerbQuizViewModel?
    var pronounQuizViewModel: PronounQuizViewModel?
    var nounGenderQuizViewModel: NounGenderQuizViewModel?
    var reflexiveQuizViewModel: ReflexiveQuizViewModel?

    init(resultsManager: TestResultsManager, verbQuizViewModel: VerbQuizViewModel? = nil, pronounQuizViewModel: PronounQuizViewModel? = nil, nounGenderQuizViewModel: NounGenderQuizViewModel? = nil, reflexiveQuizViewModel: ReflexiveQuizViewModel? = nil, initialFilter: TestFilter? = nil) {
        self.resultsManager = resultsManager
        self.verbQuizViewModel = verbQuizViewModel
        self.pronounQuizViewModel = pronounQuizViewModel
        self.nounGenderQuizViewModel = nounGenderQuizViewModel
        self.reflexiveQuizViewModel = reflexiveQuizViewModel
        if let filter = initialFilter {
            _selectedFilter = State(initialValue: filter)
        }
    }

    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Test History")
                .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetHistoryFilter"))) { notification in
            if let userInfo = notification.userInfo, let filterString = userInfo["filter"] as? String {
                switch filterString {
                case "Verbs":
                    selectedFilter = .verbs
                case "Pronouns":
                    selectedFilter = .pronouns
                case "Noun Gender":
                    selectedFilter = .gender
                case "Reflexiva pronomen":
                    selectedFilter = .reflexiva
                default:
                    selectedFilter = .all
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if resultsManager.results.isEmpty {
            emptyStateView
        } else {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TestFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 10)

                resultsListView
            }
        }
    }

    private var filteredResults: [TestResult] {
        switch selectedFilter {
        case .all:
            return resultsManager.results
        case .pronouns:
            return resultsManager.results.filter { $0.testType == "Pronouns" }
        case .gender:
            return resultsManager.results.filter { $0.testType == "Noun Gender" }
        case .verbs:
            return resultsManager.results.filter { $0.testType == "Verbs" }
        case .reflexiva:
            return resultsManager.results.filter { $0.testType == "Reflexiva pronomen" }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Test Results Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Complete a test to see your results here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var resultsListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                if filteredResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try selecting a different filter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(filteredResults) { result in
                        Button(action: {
                            selectedResult = result
                        }) {
                            TestResultRow(
                                result: result,
                                isAnimating: animatedItemId == result.id
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: resultsManager.results) { oldValue, newValue in
            animateNewItem(oldValue: oldValue, newValue: newValue)
        }
                    .sheet(item: $selectedResult) { result in
                        TestDetailModal(
                            result: result,
                            isPresented: Binding(
                                get: { selectedResult != nil },
                                set: { if !$0 { selectedResult = nil } }
                            ),
                            verbQuizViewModel: verbQuizViewModel ?? VerbQuizViewModel(),
                            pronounQuizViewModel: pronounQuizViewModel ?? PronounQuizViewModel(),
                            nounGenderQuizViewModel: nounGenderQuizViewModel ?? NounGenderQuizViewModel(),
                            reflexiveQuizViewModel: reflexiveQuizViewModel ?? ReflexiveQuizViewModel(),
                            resultsManager: resultsManager
                        )
                    }
    }

    private func animateNewItem(oldValue: [TestResult], newValue: [TestResult]) {
        if let firstItem = filteredResults.first {
            let isNewItem = oldValue.isEmpty || (oldValue.first?.id != firstItem.id)
            if isNewItem && animatedItemId == nil {
                animatedItemId = firstItem.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animatedItemId = nil
                }
            }
        }
    }

    private func deleteResults(at offsets: IndexSet) {
        // Note: Delete functionality can be added with swipe actions if needed
    }
}

struct TestResultRow: View {
    let result: TestResult
    let isAnimating: Bool
    @Environment(\.colorScheme) var colorScheme

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        return formatter
    }

    private func colorForSquare(_ number: Int) -> Color {
        // Color gradient: 1 = red, 5 = orange, 10 = green
        if number <= 5 {
            let ratio = Double(number - 1) / 4.0
            let red = 1.0
            let green = ratio * 0.65
            let blue = 0.0
            return Color(red: red, green: green, blue: blue)
        } else {
            let ratio = Double(number - 5) / 5.0
            let red = 1.0 - ratio
            let green = 0.65 + (ratio * 0.35)
            let blue = 0.0
            return Color(red: red, green: green, blue: blue)
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Text(result.testType == "Noun Gender" ? "Gender" : (result.testType == "Reflexiva pronomen" ? "Reflexiva" : result.testType))
                    .font(.body)
                    .fontWeight(.medium)
                Text("•")
                    .foregroundColor(.secondary)
                Text(dateFormatter.string(from: result.date))
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)

            HStack(spacing: -4) {
                ForEach(1...result.totalQuestions, id: \.self) { number in
                    let isScoreSquare = result.score > 0 && number == result.score
                    let size: CGFloat = isScoreSquare ? 32 : 22
                    let borderWidth: CGFloat = isScoreSquare ? 2.5 : 0

                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(colorForSquare(number))
                            .frame(width: size, height: size)

                        if borderWidth > 0 {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: borderWidth)
                                .frame(width: size, height: size)
                        }

                        Text("\(number)")
                            .font(.system(size: isScoreSquare ? 14 : 11, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                    }

                    if number < result.totalQuestions {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 12)
                    }
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 20)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isAnimating)
    }
}

#Preview {
    GrammarHistoryView(resultsManager: TestResultsManager())
}
