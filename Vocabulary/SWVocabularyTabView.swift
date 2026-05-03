//
//  SWVocabularyTabView.swift
//  Swedishly – Vocabulary tab (renamed from ContentView to avoid duplicate build output)
//
//  Created by EVYATAR DAYAN on 2026-01-23.
//

import SwiftUI

struct SWVocabularyContentView: View {
    @State private var selectedTab: Int = 2 // Default to Test (index 2)
    @State private var pendingTestFromHistory: TestHistoryItem? = nil
    @State private var cameFromHistory: Bool = false

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
                            // History view
                            HistoryView(
                                onSelectTest: { item in
                                    pendingTestFromHistory = item
                                    cameFromHistory = true
                                    selectedTab = 2
                                },
                                onSelectPractice: { _ in
                                    selectedTab = 1
                                }
                            )
                        case 1:
                            // Practice view
                            PracticeView()
                        case 2:
                            // Test view
                            SWVocabularyTestView(pendingTestFromHistory: $pendingTestFromHistory, selectedTab: $selectedTab, cameFromHistory: $cameFromHistory)
                        case 3:
                            // My list view
                            MyListView()
                        case 4:
                            // Settings view
                            SWVocabularySettingsView()
                        default:
                            SWVocabularyTestView(pendingTestFromHistory: $pendingTestFromHistory, selectedTab: $selectedTab, cameFromHistory: $cameFromHistory)
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
                        SWVocabularyTabBarButton(
                            icon: "history",
                            label: "History",
                            isCustomIcon: true,
                            isSelected: selectedTab == 0,
                            action: { selectedTab = 0 }
                        )

                        SWVocabularyTabBarButton(
                            icon: "practice",
                            label: "Practice",
                            isCustomIcon: true,
                            isSelected: selectedTab == 1,
                            action: { selectedTab = 1 }
                        )

                        SWVocabularyTabBarButton(
                            icon: "Test",
                            label: "Test",
                            isCustomIcon: true,
                            isSelected: selectedTab == 2,
                            action: { selectedTab = 2 }
                        )

                        SWVocabularyTabBarButton(
                            icon: "star",
                            label: "Words",
                            isCustomIcon: true,
                            isSelected: selectedTab == 3,
                            action: { selectedTab = 3 }
                        )

                        SWVocabularyTabBarButton(
                            icon: "settings",
                            label: "Settings",
                            isCustomIcon: true,
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

struct SWVocabularyTabBarButton: View {
    let icon: String
    let label: String
    let isCustomIcon: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon
                if isCustomIcon {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(isSelected ? .primary : .secondary)
                } else {
                    Image(systemName: icon)
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

struct Button4PlaceholderView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("4")
                .font(.title)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SWVocabularyContentView()
}
