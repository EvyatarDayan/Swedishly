//
//  SWVocabularySettingsView.swift
//  Swedishly – Vocabulary settings (standalone so SWVocabularyTabView can find it)
//

import SwiftUI

struct SWVocabularySettingsView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @StateObject private var wrongAnswersManager = WrongAnswersManager.shared
    @StateObject private var testHistoryManager = TestHistoryManager.shared
    @StateObject private var practiceHistoryManager = PracticeHistoryManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingClearCacheAlert = false
    @State private var showingClearHistoryAlert = false
    @State private var showingNotificationSettings = false
    @State private var showingLearningTips = false
    @State private var showingTermsPrivacy = false
    @State private var showingHelpSupport = false
    @State private var showingAbout = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.appRed)
                .padding(.top, 20)
                .padding(.bottom, 20)

            List {
                Section {
                    Toggle("Dark mode", isOn: $darkModeEnabled)
                }
                Section(header: Text("Data")) {
                    Button("Clear wrong answers") {
                        showingClearHistoryAlert = true
                    }
                    Button("Clear test & practice history") {
                        showingClearHistoryAlert = true
                    }
                }
                Section(header: Text("Notifications")) {
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Text("Daily reminders")
                            Spacer()
                            Text(notificationManager.notificationsEnabled ? "On" : "Off")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section {
                    Button("Learning tips") { showingLearningTips = true }
                    Button("Terms & Privacy") { showingTermsPrivacy = true }
                    Button("Help & Support") { showingHelpSupport = true }
                    Button("About") { showingAbout = true }
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsModal()
        }
        .sheet(isPresented: $showingLearningTips) {
            LearningTipsView()
        }
        .sheet(isPresented: $showingTermsPrivacy) {
            TermsPrivacyView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Clear data?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                wrongAnswersManager.clearAllWrongAnswers()
            }
        } message: {
            Text("This will clear wrong answers and reset progress.")
        }
        .alert("Clear history?", isPresented: $showingClearHistoryAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                testHistoryManager.clearAllHistory()
                practiceHistoryManager.clearAllHistory()
            }
        } message: {
            Text("All test and practice history will be removed.")
        }
    }
}

#Preview {
    SWVocabularySettingsView()
}
