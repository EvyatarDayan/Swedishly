//
//  AdjectivesContentView.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-01-28.
//

import SwiftUI
import UIKit

struct AdjectivesContentView: View {
    @State private var selectedTab: Int = 2 // Default to Compare (index 2)
    
    // Menu height constant - adjust this to change menu height
    private let menuHeight: CGFloat = 40
    // Menu button spacing - adjust this to change spacing between buttons (negative values bring them closer)
    private let menuButtonSpacing: CGFloat = -40
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Light gray background for entire view including safe area
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Main content area - switch based on selected tab
                    Group {
                        switch selectedTab {
                        case 0:
                            AdjectivesTab1View()
                        case 1:
                            AdjectivesTab2View()
                        case 2:
                            AdjectivesTab3View()
                        case 3:
                            AdjectivesTab4View()
                        case 4:
                            AdjectivesTab5View()
                        default:
                            AdjectivesTab3View()
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height - menuHeight)
                    .clipped()
                
                // Footer menu with 5 buttons - simple layout with top curved background
                ZStack(alignment: .bottom) {
                    // System background extending to bottom including safe area
                    VStack(spacing: 0) {
                        // Main menu background with curved top edges and shadow
                        UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20)
                            .fill(Color(.systemBackground))
                            .frame(width: geometry.size.width, height: menuHeight)
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: -3)
                        
                        // Extension to fill bottom safe area
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .frame(width: geometry.size.width)
                            .frame(height: geometry.safeAreaInsets.bottom)
                    }
                    
                    // Buttons
                    HStack(spacing: menuButtonSpacing) {
                        AdjectivesTabBarButton(
                            icon: "history",
                            label: "History",
                            isSelected: selectedTab == 0,
                            action: { selectedTab = 0 }
                        )
                        AdjectivesTabBarButton(
                            icon: "star",
                            label: "Antonyms",
                            isSelected: selectedTab == 1,
                            action: { selectedTab = 1 }
                        )
                        AdjectivesTabBarButton(
                            icon: "star",
                            label: "Agreement",
                            isSelected: selectedTab == 2,
                            action: { selectedTab = 2 }
                        )
                        AdjectivesTabBarButton(
                            icon: "star",
                            label: "Comparison",
                            isSelected: selectedTab == 3,
                            action: { selectedTab = 3 }
                        )
                        AdjectivesTabBarButton(
                            icon: "settings",
                            label: "Settings",
                            isSelected: selectedTab == 4,
                            action: { selectedTab = 4 }
                        )
                    }
                    .frame(width: geometry.size.width, height: menuHeight)
                }
                .zIndex(1) // Ensure menu is above content
                }
            }
        }
    }
}

struct AdjectivesTabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon - check if it's an image name or text
                if icon == "star" || icon == "settings" || icon == "history" {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(isSelected ? .primary : .secondary)
                } else {
                    Text(icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .primary : .secondary)
                }
                
                // Text below icon
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, -30)
            .padding(.bottom, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(true)
    }
}

// Placeholder views for each tab (used by standalone Adjectives app)
struct AdjectivesTab1View: View {
    var body: some View {
        AdjectivesHistoryView()
    }
}

struct AdjectivesTab2View: View {
    var body: some View {
        AntonymsView()
    }
}

struct AdjectivesTab3View: View {
    var body: some View {
        AgreementView()
    }
}

// MARK: - Option Button (Adjectives)
struct AdjectivesOptionButton: View {
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

// MARK: - Practice Summary Modal (Adjectives)
struct AdjectivesPracticeSummaryModal: View {
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
                
                Text(motivationalMessage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.appRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Pie chart
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 30)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: correctRatio)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    if wrongRatio > 0 {
                        Circle()
                            .trim(from: correctRatio, to: correctRatio + wrongRatio)
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                    }
                    
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
                
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        VStack(spacing: 8) {
                            Text("\(questions)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Questions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            Text("\(correct)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                            Text("Correct")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
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

// MARK: - Data Models (Adjectives – prefixed to avoid conflict with Vocabulary)
struct AdjectivesTestWord: Identifiable {
    let id = UUID()
    let swedish: String
    let english: String
    let example: AdjectivesWordExample?
    
    init(swedish: String, english: String, example: AdjectivesWordExample? = nil) {
        self.swedish = swedish
        self.english = english
        self.example = example
    }
}

struct AdjectivesWordExample {
    let sv: String
    let en: String
}

// MARK: - Test Data Manager (Adjectives)
class AdjectivesTestDataManager {
    static let shared = AdjectivesTestDataManager()
    
    private let sampleWords: [AdjectivesTestWord] = [
        AdjectivesTestWord(swedish: "hej", english: "hello", example: AdjectivesWordExample(sv: "Hej, hur mår du?", en: "Hello, how are you?")),
        AdjectivesTestWord(swedish: "tack", english: "thank you", example: AdjectivesWordExample(sv: "Tack så mycket!", en: "Thank you very much!")),
        AdjectivesTestWord(swedish: "ja", english: "yes", example: AdjectivesWordExample(sv: "Ja, det stämmer.", en: "Yes, that's correct.")),
        AdjectivesTestWord(swedish: "nej", english: "no", example: AdjectivesWordExample(sv: "Nej, det är inte rätt.", en: "No, that's not right.")),
        AdjectivesTestWord(swedish: "god morgon", english: "good morning", example: AdjectivesWordExample(sv: "God morgon! Hur sov du?", en: "Good morning! How did you sleep?")),
        AdjectivesTestWord(swedish: "god kväll", english: "good evening", example: AdjectivesWordExample(sv: "God kväll, hur var dagen?", en: "Good evening, how was your day?")),
        AdjectivesTestWord(swedish: "välkommen", english: "welcome", example: AdjectivesWordExample(sv: "Välkommen till Sverige!", en: "Welcome to Sweden!")),
        AdjectivesTestWord(swedish: "ursäkta", english: "excuse me", example: AdjectivesWordExample(sv: "Ursäkta, var är toaletten?", en: "Excuse me, where is the bathroom?")),
        AdjectivesTestWord(swedish: "förlåt", english: "sorry", example: AdjectivesWordExample(sv: "Förlåt, jag är sen.", en: "Sorry, I'm late.")),
        AdjectivesTestWord(swedish: "adjö", english: "goodbye", example: AdjectivesWordExample(sv: "Adjö, vi ses imorgon!", en: "Goodbye, see you tomorrow!")),
        AdjectivesTestWord(swedish: "vatten", english: "water", example: AdjectivesWordExample(sv: "Kan jag få lite vatten?", en: "Can I have some water?")),
        AdjectivesTestWord(swedish: "kaffe", english: "coffee", example: AdjectivesWordExample(sv: "Jag dricker kaffe varje morgon.", en: "I drink coffee every morning.")),
        AdjectivesTestWord(swedish: "bröd", english: "bread", example: AdjectivesWordExample(sv: "Vi köper bröd på bageriet.", en: "We buy bread at the bakery.")),
        AdjectivesTestWord(swedish: "äpple", english: "apple", example: AdjectivesWordExample(sv: "Ett rött äpple är gott.", en: "A red apple is good.")),
        AdjectivesTestWord(swedish: "hus", english: "house", example: AdjectivesWordExample(sv: "Vi bor i ett stort hus.", en: "We live in a big house.")),
        AdjectivesTestWord(swedish: "bil", english: "car", example: AdjectivesWordExample(sv: "Min bil är blå.", en: "My car is blue.")),
        AdjectivesTestWord(swedish: "hund", english: "dog", example: AdjectivesWordExample(sv: "Hunden är min bästa vän.", en: "The dog is my best friend.")),
        AdjectivesTestWord(swedish: "katt", english: "cat", example: AdjectivesWordExample(sv: "Katterna sover på soffan.", en: "The cats sleep on the sofa.")),
        AdjectivesTestWord(swedish: "bok", english: "book", example: AdjectivesWordExample(sv: "Jag läser en bok.", en: "I'm reading a book.")),
        AdjectivesTestWord(swedish: "skola", english: "school", example: AdjectivesWordExample(sv: "Barnen går till skolan.", en: "The children go to school."))
    ]
    
    func getAllWords() -> [AdjectivesTestWord] {
        return sampleWords
    }
    
    func getRandomWords(count: Int) -> [AdjectivesTestWord] {
        return Array(sampleWords.shuffled().prefix(count))
    }
}

struct AdjectivesTab4View: View {
    var body: some View {
        ComparisonView()
    }
}

struct AdjectivesTab5View: View {
    var body: some View {
        AdjectivesSettingsView()
    }
}

#Preview {
    AdjectivesContentView()
}
