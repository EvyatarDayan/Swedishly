//
//  GrammarLastSessionPieChart.swift
//  Shared ring chart + grammar initial layout (matches Vocabulary PracticeView empty state).
//

import SwiftUI

// MARK: - Ring chart (same design/animation as PracticeView LastSessionPieChart)

struct SessionSuccessRingChart: View {
    let correct: Int
    let questions: Int
    let dateTaken: Date
    let successPercentage: Int
    /// e.g. "Your last practice" or "Your last test"
    let titlePrefix: String
    /// When set, replaces the title entirely (used for empty state).
    var titleOverride: String? = nil
    /// When set, shown after `titlePrefix` instead of the formatted `dateTaken` (e.g. "—" when no tests yet).
    var dateCaptionOverride: String? = nil

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
        guard questions > 0 else { return 0 }
        return Double(correct) / Double(questions)
    }

    private var wrongRatio: Double {
        guard questions > 0 else { return 0 }
        return Double(questions - correct) / Double(questions)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(titleOverride ?? "\(titlePrefix) \(dateCaptionOverride ?? dateFormatter.string(from: dateTaken))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()
                .frame(height: 16)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 20)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: animatedCorrectRatio)
                    .stroke(Color(red: 0.4, green: 0.8, blue: 0.4), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                if wrongRatio > 0 {
                    Circle()
                        .trim(from: animatedCorrectRatio, to: animatedCorrectRatio + animatedWrongRatio)
                        .stroke(Color(red: 1.0, green: 0.5, blue: 0.5), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

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
            animatedCorrectRatio = 0
            animatedWrongRatio = 0
            animatedPercentage = 0
            chartScale = 0.8
            chartOpacity = 0
            withAnimation(.easeOut(duration: 0.5)) {
                chartScale = 1.0
                chartOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                animatedCorrectRatio = correctRatio
            }
            if wrongRatio > 0 {
                withAnimation(.easeInOut(duration: 0.8).delay(0.6)) {
                    animatedWrongRatio = wrongRatio
                }
            }
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

// MARK: - Grammar test last session (wrapper)

struct GrammarLastSessionPieChart: View {
    let correct: Int
    let questions: Int
    let dateTaken: Date
    let successPercentage: Int

    var body: some View {
        SessionSuccessRingChart(
            correct: correct,
            questions: questions,
            dateTaken: dateTaken,
            successPercentage: successPercentage,
            titlePrefix: "Your last test"
        )
    }
}

extension GrammarLastSessionPieChart {
    static func lastResult(for testType: String, in results: [TestResult]) -> TestResult? {
        results.first { $0.testType == testType }
    }
}

// MARK: - Grammar initial screen (same structure as Vocabulary PracticeView)

struct GrammarInitialScreenView: View {
    @ObservedObject var resultsManager: TestResultsManager
    let imageName: String
    var imageUsesTemplate: Bool = true
    let subtitle: String
    let grammarTestType: String
    let onStart: () -> Void

    private var lastResult: TestResult? {
        GrammarLastSessionPieChart.lastResult(for: grammarTestType, in: resultsManager.results)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Group {
                if imageUsesTemplate {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.appRed)
                } else {
                    Image(imageName)
                        .resizable()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80)

            Text(subtitle)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .padding(.bottom, 15)

            Button(action: onStart) {
                Text("Start new test")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appRed)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Button(action: {
                NotificationCenter.default.post(name: .openHistoryWithGrammarFilter, object: nil)
            }) {
                Text("My previous tests")
                    .font(.headline)
                    .foregroundColor(.appRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appRed.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 60)
            .padding(.top, 12)

            Group {
                if let last = lastResult {
                    SessionSuccessRingChart(
                        correct: last.score,
                        questions: last.totalQuestions,
                        dateTaken: last.date,
                        successPercentage: Int(round(last.percentage)),
                        titlePrefix: "Your last test"
                    )
                    .id(last.id)
                } else {
                    SessionSuccessRingChart(
                        correct: 0,
                        questions: 0,
                        dateTaken: Date(),
                        successPercentage: 0,
                        titlePrefix: "Your last test",
                        titleOverride: "No test information yet"
                    )
                    .id("grammar-no-session-\(grammarTestType)")
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
