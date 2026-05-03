//
//  MainView.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI
import Combine

struct MainView: View {
    @State private var selectedTab: Int = 2 // Start with "Verbs" in the middle
    @AppStorage("darkMode") private var darkMode = false
    var menuHorizontalSpacing: CGFloat = -40 // Horizontal spacing between menu buttons
    
    // Create ViewModels at MainView level to persist state across navigation
    @StateObject private var verbQuizViewModel = VerbQuizViewModel()
    @StateObject private var pronounQuizViewModel = PronounQuizViewModel()
    @StateObject private var nounGenderQuizViewModel = NounGenderQuizViewModel()
    @StateObject private var reflexiveQuizViewModel = ReflexiveQuizViewModel()
    @StateObject private var testResultsManager = TestResultsManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area - keep all views in hierarchy, just show/hide them
            ZStack {
                // Tab 0: History
                GrammarHistoryView(
                    resultsManager: testResultsManager,
                    verbQuizViewModel: verbQuizViewModel,
                    pronounQuizViewModel: pronounQuizViewModel,
                    nounGenderQuizViewModel: nounGenderQuizViewModel,
                    reflexiveQuizViewModel: reflexiveQuizViewModel
                )
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)
                
                // Tab 1: Pronouns
                PronounTestView(viewModel: pronounQuizViewModel, resultsManager: testResultsManager)
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)
                
                // Tab 2: Verbs
                GrammarVerbTestView(viewModel: verbQuizViewModel, resultsManager: testResultsManager)
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)
                
                // Tab 3: Reflexiva pronomen
                ReflexiveTestView(viewModel: reflexiveQuizViewModel, resultsManager: testResultsManager)
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 3)
                
                // Tab 4: Noun Gender
                NounGenderTestView(viewModel: nounGenderQuizViewModel, resultsManager: testResultsManager)
                    .opacity(selectedTab == 4 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 4)
                
                // Tab 5: Settings
                GrammarSettingsView(resultsManager: testResultsManager)
                    .opacity(selectedTab == 5 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom menu bar with glass effect
            HStack(spacing: menuHorizontalSpacing) {
                MenuButton(title: "History", iconName: "clock.fill", index: 0, isSelected: selectedTab == 0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
                
                MenuButton(title: "Pronouns", iconName: "pronouns", index: 1, isSelected: selectedTab == 1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
                
                MenuButton(title: "Verbs", iconName: "verbs", index: 2, isSelected: selectedTab == 2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
                
                MenuButton(title: "Reflexiva", iconName: "verbs", index: 3, isSelected: selectedTab == 3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 3
                    }
                }
                
                MenuButton(title: "Gender", iconName: "gender", index: 4, isSelected: selectedTab == 4) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 4
                    }
                }
                
                MenuButton(title: "Settings", iconName: "gearshape.fill", index: 5, isSelected: selectedTab == 5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 5
                    }
                }
            }
            .frame(height: 88)
            .background {
                // Glass effect background
                ZStack {
                    // Blur material
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    
                    // Top border
                    VStack {
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 0.5)
                        Spacer()
                    }
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(darkMode ? .dark : .light)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToHistory"))) { notification in
                // Post filter notification if filter is specified
                if let userInfo = notification.userInfo, let filterString = userInfo["filter"] as? String {
                    NotificationCenter.default.post(name: NSNotification.Name("SetHistoryFilter"), object: nil, userInfo: ["filter": filterString])
                } else {
                    // Reset to all if no filter specified
                    NotificationCenter.default.post(name: NSNotification.Name("SetHistoryFilter"), object: nil, userInfo: ["filter": "All"])
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTest"))) { notification in
                if let userInfo = notification.userInfo, let tab = userInfo["tab"] as? Int {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
    }
}

struct MenuButton: View {
    let title: String
    let iconName: String
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    var verticalSpacing: CGFloat = 5 // Spacing between icon and text
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: verticalSpacing) {
                // Check if it's an asset image or SF Symbol
                if iconName == "gender" || iconName == "pronouns" || iconName == "verbs" {
                    Image(iconName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .foregroundColor(isSelected ? .primary : .secondary)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .primary : .secondary)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainView()
}
