//
//  TestsView.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI

struct TestsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var testManager = TestManager.shared
    @State private var selectedVerb: Verb?
    @State private var selectedTest: Test?
    @Binding var testToAnimate: String?
    @State private var showAnimatedTest: Bool = false
    @State private var searchText: String = ""
    @Environment(\.colorScheme) var colorScheme

    init(testToAnimate: Binding<String?> = .constant(nil)) {
        self._testToAnimate = testToAnimate
    }

    var filteredTests: [Test] {
        if searchText.isEmpty {
            return testManager.tests
        }
        return testManager.tests.filter { test in
            test.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            BackButtonRow(onBack: { dismiss() })
            // Search Bar
            SearchBar(text: $searchText, placeholder: "Search for a test...")
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 18)
                
                // Content
                if testManager.tests.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No tests yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Create a test from the Practice view")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else if filteredTests.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Try searching with different words")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(Array(filteredTests.enumerated()), id: \.element.id) { index, test in
                            TestRow(test: test, testManager: testManager) {
                                selectedTest = test
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .scaleEffect(shouldAnimateTest(test.id) ? (showAnimatedTest ? 1 : 0) : 1)
                            .opacity(shouldAnimateTest(test.id) ? (showAnimatedTest ? 1 : 0) : 1)
                            .animation(
                                shouldAnimateTest(test.id) ? .spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.08) : nil,
                                value: showAnimatedTest
                            )
                        }
                        .onDelete(perform: deleteTests)
                    }
                    .listStyle(.plain)
                    .onAppear {
                        // Check if we need to animate a specific test
                        if testToAnimate != nil {
                            // Start appear animation after a delay
                            showAnimatedTest = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showAnimatedTest = true
                                // Clear the animation trigger after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    testToAnimate = nil
                                }
                            }
                        }
                    }
                    .onChange(of: testToAnimate) { oldValue, newValue in
                        if newValue != nil {
                            // Start appear animation after a delay
                            showAnimatedTest = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showAnimatedTest = true
                                // Clear the animation trigger after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    testToAnimate = nil
                                }
                            }
                        } else {
                            // Clear animation state when testToAnimate is cleared
                            showAnimatedTest = false
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SplitTitleView("Tests", splitIndex: 3)
                }
            }
            .sheet(item: $selectedTest) { test in
                TestDetailView(test: test)
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func deleteTests(at offsets: IndexSet) {
        for index in offsets {
            testManager.deleteTest(testManager.tests[index])
        }
    }
    
    private func shouldAnimateTest(_ testId: String) -> Bool {
        return testToAnimate == testId
    }
}

struct TestRow: View {
    @Environment(\.colorScheme) var colorScheme
    let test: Test
    @ObservedObject var testManager: TestManager
    let onTap: () -> Void
    
    private var currentTest: Test? {
        testManager.tests.first { $0.id == test.id }
    }
    
    private var scoreColor: Color {
        let percentage = currentTest?.totalScorePercentage ?? test.totalScorePercentage
        guard let percentage = percentage else { return .secondary }
        if percentage >= 80 {
            return .green
        } else if percentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var dateTimeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.string(from: test.createdAt)
    }
    
    var body: some View {
        HStack {
            // Left: Last Score
            VStack(spacing: 2) {
                Image("stars")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .foregroundColor(.secondary)
                
                if let percentage = currentTest?.totalScorePercentage ?? test.totalScorePercentage {
                    Text("\(percentage)%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                } else {
                    Text("N/A")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Center: Test name and date
            VStack(alignment: .center, spacing: 4) {
                Text(test.name)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Date and time below the name
                Text(dateTimeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Right: Play button
            Button(action: onTap) {
                Image("play-button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
//                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal, -23)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TestDetailView: View {
    @StateObject private var testManager = TestManager.shared
    let test: Test
    @Environment(\.dismiss) var dismiss
    @State private var selectedVerb: Verb?
    @State private var refreshId = UUID()
    @State private var showVerbs = false
    @State private var isFirstAppearance = true
    @State private var showCompletionAlert = false
    @State private var completionScore: Int = 0
    @State private var wasCompletedBefore = false
    
    private var currentTest: Test? {
        testManager.tests.first { $0.id == test.id }
    }
    
    private var verbs: [Verb] {
        currentTest?.verbs ?? test.verbs
    }
    
    private var testToUse: Test {
        currentTest ?? test
    }
    
    var body: some View {
        NavigationView {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 0) {
                        // Information message below title
                        if !verbs.isEmpty {
                            Text("You’re almost there! Complete all verbs to finish the test.")
                                .font(.system(size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.top, 35)
                                .padding(.bottom, 8)
                        }
                        
                        // Top spacer for navigation title area
                        Spacer()
                        
                        // Verb list
                        if verbs.isEmpty {
                            Text("No verbs available")
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(verbs.enumerated()), id: \.element.id) { index, verb in
                                    AnimatedTestVerbRow(
                                        verb: verb,
                                        test: testToUse,
                                        showVerbs: showVerbs,
                                        index: index,
                                        totalCount: verbs.count,
                                        onOpen: {
                                            selectedVerb = verb
                                        },
                                        onTap: {
                                            selectedVerb = verb
                                        }
                                    )
                                    .onTapGesture {
                                        selectedVerb = verb
                                    }
                                }
                            }
                            .id(refreshId)
                            .padding(.horizontal, 16)
                            .padding(.top, -35)
                            
                            // All done button
                            Button(action: {
                                dismiss()
                            }) {
                                Text("All done")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 100)
                            .padding(.top, 50)
                        }
                        
                        // Bottom spacer
                        Spacer()
                    }
                )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    let testName = test.name
                    let splitIndex = testName.count / 2
                    SplitTitleView(testName, splitIndex: splitIndex)
                }
            }
            .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let currentTest = currentTest, currentTest.isCompleted {
                        Button("Reset") {
                            // First make verbs disappear one by one
                            showVerbs = false
                            let verbsCount = verbs.count
                            // Then reset after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(verbsCount) * 0.08 + 0.1) {
                                if let index = testManager.tests.firstIndex(where: { $0.id == test.id }) {
                                    var updatedTest = testManager.tests[index]
                                    updatedTest.verbScores = [:]
                                    updatedTest.totalScorePercentage = nil
                                    updatedTest.verbAnswers = [:]
                                    updatedTest.verbResults = [:]
                                    testManager.tests[index] = updatedTest
                                    testManager.saveTests()
                                    refreshId = UUID()
                                }
                                // Then make them appear again
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showVerbs = true
                                }
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Check if test is already completed when view appears
            if let currentTest = testManager.tests.first(where: { $0.id == test.id }) {
                wasCompletedBefore = currentTest.isCompleted
            } else {
                wasCompletedBefore = test.isCompleted
            }
            
            if isFirstAppearance {
                showVerbs = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showVerbs = true
                }
                isFirstAppearance = false
            } else {
                // Show immediately when returning from answer view
                showVerbs = true
            }
        }
        .sheet(item: $selectedVerb) { verb in
            VerbDetailView(verb: verb, isPracticeMode: true, isTestMode: true, testId: currentTest?.id ?? test.id)
                .onDisappear {
                    // Just refresh the view, don't trigger animation
                    refreshId = UUID()
                    
                    // Check if test just became completed (wasn't completed before, but is now)
                    if let currentTest = testManager.tests.first(where: { $0.id == test.id }), currentTest.isCompleted {
                        // Only show alert if test was NOT completed before
                        if !wasCompletedBefore {
                            let percentage = currentTest.calculatedPercentage
                            completionScore = percentage
                            
                            // Update the test with the percentage
                            if let index = testManager.tests.firstIndex(where: { $0.id == test.id }) {
                                var updatedTest = testManager.tests[index]
                                updatedTest.totalScorePercentage = percentage
                                testManager.tests[index] = updatedTest
                                testManager.saveTests()
                            }
                            
                            // Mark as completed so we don't show again
                            wasCompletedBefore = true
                            
                            // Show completion alert automatically
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showCompletionAlert = true
                            }
                        }
                    }
                }
        }
        .onChange(of: testManager.tests) { oldValue, newValue in
            // Just refresh the view, don't trigger animation
            refreshId = UUID()
        }
        .alert("All done!", isPresented: $showCompletionAlert) {
            Button("OK") {
                // Just close the alert, don't dismiss the view
            }
        } message: {
            Text("Your score is \(completionScore)%")
        }
    }
    
}

struct TestVerbRow: View {
    @Environment(\.colorScheme) var colorScheme
    let verb: Verb
    let test: Test
    var onOpen: (() -> Void)? = nil
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @State private var isPlaying = false
    
    private var score: Int {
        test.verbScores[verb.id] ?? 0
    }
    
    private var scoreColor: Color {
        switch score {
        case 3: return .green
        case 2: return .orange
        case 1, 0: return .red
        default: return .secondary
        }
    }
    
    var body: some View {
        HStack {
            // Audio button on the left
            Button(action: {
                if isPlaying {
                    speechSynthesizer.stop()
                    isPlaying = false
                } else {
                    speechSynthesizer.speak(verb.infinitive, language: "sv-SE") {
                        isPlaying = false
                    }
                    isPlaying = true
                }
            }) {
                Image("audio-headphone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .opacity(isPlaying ? 0.5 : 1.0)
                    .animation(
                        isPlaying ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                        value: isPlaying
                    )
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text(verb.infinitive)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                if !verb.english.isEmpty && verb.english[0] != "translation" {
                    Text(verb.english.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Score label
                if test.verbScores.keys.contains(verb.id) {
                    Text("\(score)/3")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(scoreColor)
                }
                
                // Open button on the right
                Button(action: {
                    onOpen?()
                }) {
                    Image("play-button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 37, height: 37)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AnimatedTestVerbRow: View {
    let verb: Verb
    let test: Test
    let showVerbs: Bool
    let index: Int
    let totalCount: Int
    let onOpen: () -> Void
    let onTap: () -> Void
    
    private var delay: Double {
        showVerbs ? Double(index) * 0.08 : Double(totalCount - 1 - index) * 0.08
    }
    
    var body: some View {
        TestVerbRow(verb: verb, test: test, onOpen: onOpen)
            .onTapGesture {
                onTap()
            }
            .scaleEffect(showVerbs ? 1 : 0)
            .opacity(showVerbs ? 1 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.75)
                    .delay(delay),
                value: showVerbs
            )
    }
}

#Preview {
    TestsView()
}

