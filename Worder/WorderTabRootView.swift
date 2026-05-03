//
//  WorderTabRootView.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-02-01.
//

import SwiftUI
import UIKit

struct WorderTabRootView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var selectedTab: Int = 2 // Default to Practice (index 2)
    @State private var showingLogo: Bool = true
    
    private let menuHeight: CGFloat = 40
    private let menuButtonSpacing: CGFloat = -40
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                        case 0:
                            WorderHistoryView()
                        case 1:
                            WorderTestView()
                        case 2:
                            WorderPracticeTabPlaceholder()
                        case 3:
                            WorderListenTabPlaceholder()
                        case 4:
                            WorderSettingsView()
                        default:
                            WorderPracticeTabPlaceholder()
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height - menuHeight)
                    .clipped()
                    
                    ZStack(alignment: .bottom) {
                        VStack(spacing: 0) {
                            UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20)
                                .fill(Color(.systemBackground))
                                .frame(width: geometry.size.width, height: menuHeight)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: -3)
                            
                            Rectangle()
                                .fill(Color(.systemBackground))
                                .frame(width: geometry.size.width)
                                .frame(height: geometry.safeAreaInsets.bottom)
                        }
                        
                        HStack(spacing: menuButtonSpacing) {
                            WorderTabBarButton(icon: "history", label: "History", isSelected: selectedTab == 0, action: { selectedTab = 0 })
                            WorderTabBarButton(icon: "test", label: "Test", isSelected: selectedTab == 1, action: { selectedTab = 1 })
                            WorderTabBarButton(icon: "practice", label: "Practice", isSelected: selectedTab == 2, action: { selectedTab = 2 })
                            WorderTabBarButton(icon: "star", label: "My List", isSelected: selectedTab == 3, action: { selectedTab = 3 })
                            WorderTabBarButton(icon: "settings", label: "Settings", isSelected: selectedTab == 4, action: { selectedTab = 4 })
                        }
                        .frame(width: geometry.size.width, height: menuHeight)
                    }
                    .zIndex(1)
                }
                
                if showingLogo {
                    WorderLogoView {
                        withAnimation { showingLogo = false }
                    }
                    .zIndex(100)
                }
            }
            .preferredColorScheme(darkModeEnabled ? .dark : nil)
        }
    }
}

struct WorderTabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    private static let assetIcons = ["history", "star", "practice", "settings", "test"]
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if Self.assetIcons.contains(icon) {
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

struct WorderPracticeTabPlaceholder: View {
    var body: some View {
        WorderPracticeView()
    }
}

struct WorderListenTabPlaceholder: View {
    var body: some View {
        WorderMyListView()
    }
}

struct PlaceholderTabView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WorderTabRootView()
}
