//
//  MainTabView.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 2 // Default to Search (index 2)
    @State private var testToAnimate: String? = nil // ID of test to animate
    
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
                            TestsView(testToAnimate: $testToAnimate)
                        case 1:
                            VerbsPracticeView(selectedTab: $selectedTab, testToAnimate: $testToAnimate)
                        case 2:
                            SearchView()
                        case 3:
                            FavoritesView()
                        case 4:
                            VerbsSettingsView()
                        default:
                            SearchView()
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
                            VerbsTabBarButton(
                                icon: "Test",
                                label: "Tests",
                                isCustomIcon: true,
                                isSelected: selectedTab == 0,
                                action: { selectedTab = 0 }
                            )
                            
                            VerbsTabBarButton(
                                icon: "practice",
                                label: "Practice",
                                isCustomIcon: true,
                                isSelected: selectedTab == 1,
                                action: { selectedTab = 1 }
                            )
                            
                            VerbsTabBarButton(
                                icon: "verbs",
                                label: "Verbs",
                                isCustomIcon: true,
                                isSelected: selectedTab == 2,
                                action: { selectedTab = 2 }
                            )
                            
                            VerbsTabBarButton(
                                icon: "star",
                                label: "Favorites",
                                isCustomIcon: true,
                                isSelected: selectedTab == 3,
                                action: { selectedTab = 3 }
                            )
                            
                            VerbsTabBarButton(
                                icon: "gearshape",
                                label: "Settings",
                                isCustomIcon: false,
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

struct VerbsTabBarButton: View {
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

#Preview {
    MainTabView()
}

