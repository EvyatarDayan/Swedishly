//
//  AppColors.swift
//  Swedishly
//

import SwiftUI

extension Color {
    /// Brand red — #d83c49
    static let appRed = Color(red: 216 / 255, green: 60 / 255, blue: 73 / 255)
}

/// Plain appRed text action for settings modal toolbars (no native button chrome).
struct SettingsModalPlainButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(.appRed)
        }
        .buttonStyle(.plain)
    }
}

/// Toolbar item wrapper that hides iOS 26 liquid-glass button backgrounds.
struct SettingsModalToolbarItem<Content: View>: ToolbarContent {
    let placement: ToolbarItemPlacement
    @ViewBuilder let content: () -> Content

    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: placement, content: content)
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: placement, content: content)
        }
    }
}
