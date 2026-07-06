//
//  VerbsPracticeView.swift
//  SWVerbs (renamed from PracticeView to avoid conflict with Vocabulary)
//

import SwiftUI

struct VerbsPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VerbViewModel()
    @StateObject private var testManager = TestManager.shared
    @State private var practiceVerbs: [Verb] = []
    @State private var isPracticing = false
    @State private var selectedVerb: Verb?
    @State private var showTestAddedAlert = false
    @State private var newTestName: String = ""
    @State private var hasSetAsTest = false
    @State private var showVerbs = false
    @State private var isFirstAppearance = true
    @State private var testAddedAlertDismissTask: Task<Void, Never>?
    @Binding var selectedTab: Int
    @Binding var testToAnimate: String?

    init(selectedTab: Binding<Int> = .constant(2), testToAnimate: Binding<String?> = .constant(nil)) {
        self._selectedTab = selectedTab
        self._testToAnimate = testToAnimate
    }

    var body: some View {
        VStack(spacing: 0) {
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
                Button(action: refreshPractice) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appRed)
                }
                .padding(.top, 8)
                .padding(.trailing, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            if !isPracticing {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Preparing practice...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    startPractice(count: 5)
                }
            } else {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 0) {
                            if !practiceVerbs.isEmpty && !viewModel.isLoading {
                                Text("Practice these verbs and test yourself when you're ready.")
                                    .font(.system(size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 35)
                                    .padding(.bottom, 20)
                            }
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                Text("Loading verbs...")
                                    .foregroundColor(.secondary)
                                    .padding(.top)
                            } else if practiceVerbs.isEmpty {
                                Text("No verbs available")
                                    .foregroundColor(.secondary)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(practiceVerbs.enumerated()), id: \.element.id) { index, verb in
                                        VerbRow(verb: verb, onOpen: { selectedVerb = verb })
                                            .onTapGesture { selectedVerb = verb }
                                            .scaleEffect(showVerbs ? 1 : 0)
                                            .opacity(showVerbs ? 1 : 0)
                                            .animation(
                                                .spring(response: 0.4, dampingFraction: 0.75)
                                                    .delay(showVerbs ? Double(index) * 0.08 : Double(practiceVerbs.count - 1 - index) * 0.08),
                                                value: showVerbs
                                            )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, -35)
                                .onAppear {
                                    if isFirstAppearance {
                                        showVerbs = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showVerbs = true }
                                        isFirstAppearance = false
                                    } else {
                                        showVerbs = true
                                    }
                                }
                                .onChange(of: practiceVerbs.count) { _, _ in
                                    showVerbs = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(practiceVerbs.count) * 0.08 + 0.1) { showVerbs = true }
                                }
                                Button(action: {
                                    let testCountBefore = testManager.tests.count
                                    testManager.addTest(verbs: practiceVerbs)
                                    if testManager.tests.count > testCountBefore, let newTest = testManager.tests.first {
                                        newTestName = newTest.name
                                        showTestAddedAlert = true
                                    }
                                    hasSetAsTest = true
                                }) {
                                    Text("Set as Test")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(hasSetAsTest ? Color.gray : Color.appRed)
                                        .cornerRadius(12)
                                }
                                .disabled(hasSetAsTest)
                                .padding(.horizontal, 100)
                                .padding(.top, 50)
                            }
                            Spacer()
                        }
                    )
                    .sheet(item: $selectedVerb) { verb in
                        VerbDetailView(verb: verb, isPracticeMode: true)
                    }
                    .alert("New test added as \"\(newTestName)\"", isPresented: $showTestAddedAlert) {
                        Button("OK") {
                            dismissTestAddedAlert()
                        }
                    }
                    .onChange(of: showTestAddedAlert) { _, isShowing in
                        if isShowing {
                            scheduleTestAddedAlertAutoDismiss()
                        } else {
                            testAddedAlertDismissTask?.cancel()
                            testAddedAlertDismissTask = nil
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func dismissTestAddedAlert() {
        testAddedAlertDismissTask?.cancel()
        testAddedAlertDismissTask = nil
        showTestAddedAlert = false
    }

    private func scheduleTestAddedAlertAutoDismiss() {
        testAddedAlertDismissTask?.cancel()
        testAddedAlertDismissTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                showTestAddedAlert = false
            }
        }
    }

    private func startPractice(count: Int) {
        guard !viewModel.verbs.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startPractice(count: count) }
            return
        }
        let shuffled = viewModel.verbs.shuffled()
        practiceVerbs = Array(shuffled.prefix(count))
        isPracticing = true
        hasSetAsTest = false
    }

    private func refreshPractice() {
        guard !viewModel.verbs.isEmpty else { return }
        // Animate out (same reverse-order delay as list)
        showVerbs = false
        let outDuration = practiceVerbs.isEmpty ? 0.1 : Double(practiceVerbs.count) * 0.08 + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + outDuration) {
            let shuffled = viewModel.verbs.shuffled()
            practiceVerbs = Array(shuffled.prefix(5))
            hasSetAsTest = false
            // Animate in after brief delay (same as initial appearance: 0.1s then staggered)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showVerbs = true
            }
        }
    }
}

#Preview {
    VerbsPracticeView()
}
