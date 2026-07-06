//
//  GrammarOptionButton.swift
//  Swedishly
//
//  Shared option button for Grammar question views — matches Adjectives design:
//  dividers, answer colors (green/red/white), blue border, system checkmark/xmark icons.
//

import SwiftUI

// MARK: - Sentence with blank (same design as Adjectives: bold sentence, blue placeholder/answer)
enum GrammarSentenceStyle {
    /// Returns Text with bold sentence and blue blank/answer (matches Adjectives ComparisonView).
    static func sentenceWithBlank(_ sentence: String, blankMarker: String = "____", displayText: String?) -> Text {
        let parts = sentence.components(separatedBy: blankMarker)
        let blankOrAnswer = displayText ?? blankMarker
        let fullText: String
        if parts.count >= 2 {
            fullText = parts[0] + blankOrAnswer + parts[1]
        } else {
            return Text(sentence)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
        }
        var attributedString = AttributedString(fullText)
        var fullContainer = AttributeContainer()
        fullContainer.font = .system(size: 20, weight: .bold)
        fullContainer.foregroundColor = Color.primary
        let fullRange = attributedString.startIndex..<attributedString.endIndex
        attributedString[fullRange].setAttributes(fullContainer)
        if let range = attributedString.range(of: blankOrAnswer) {
            var blueContainer = AttributeContainer()
            blueContainer.foregroundColor = .appRed
            blueContainer.font = .system(size: 20, weight: .bold)
            attributedString[range].setAttributes(blueContainer)
        }
        return Text(attributedString)
    }
}

struct GrammarOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let isDisabled: Bool
    var isAnimating: Bool = false
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

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
                    .stroke(Color.appRed, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .scaleEffect(isAnimating ? 1.10 : 1.0)
            .animation(.easeInOut(duration: 0.5), value: isAnimating)
        }
        .disabled(isDisabled)
    }

    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.15)
        } else if isIncorrect {
            return Color.red.opacity(0.15)
        } else if isSelected {
            return Color.appRed.opacity(0.1)
        } else {
            return colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        }
    }
}
