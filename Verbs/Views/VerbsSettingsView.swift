//
//  VerbsSettingsView.swift
//  SWVerbs (renamed from SettingsView to avoid conflict)
//

import SwiftUI
import UserNotifications

struct VerbsSettingsView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @StateObject private var notificationManager = VerbsNotificationManager.shared
    @State private var selectedTime = Date()
    @State private var isReminderEnabled = false
    @State private var showingPermissionAlert = false
    @State private var showingClearTestsAlert = false
    @State private var showingClearFavoritesAlert = false
    @State private var showingHelpSupport = false
    @State private var showingTermsPrivacy = false
    @State private var showingAbout = false
    @State private var showingLearningTips = false
    @StateObject private var testManager = TestManager.shared
    @StateObject private var favoriteManager = FavoriteManager.shared

    var body: some View {
        NavigationView {
            List {
                // Dark Mode Section
                Section(header: Text("MODE")) {
                    HStack(spacing: 12) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.appRed, Color.appRed.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .font(.body)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: true)

                            Text("Enable dark mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                        .frame(width: 8)

                        Toggle("", isOn: $darkModeEnabled)
                            .scaleEffect(0.8)
                    }
                }

                // Schedule Section
                Section(header: Text("SCHEDULE")) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.appRed, Color.appRed.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Reminder")
                                .font(.body)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: true)

                            Text("Set learning reminder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                        .frame(width: 8)

                        Toggle("", isOn: $isReminderEnabled)
                            .scaleEffect(0.8)
                            .onChange(of: isReminderEnabled) { _, newValue in
                                if newValue {
                                    requestNotificationPermission()
                                } else {
                                    notificationManager.cancelAllNotifications()
                                }
                            }
                    }

                    if isReminderEnabled {
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .onChange(of: selectedTime) { _, _ in
                                if isReminderEnabled { scheduleNotification() }
                            }

                        if let nextNotificationDate = notificationManager.nextNotificationDate {
                            HStack {
                                Text("Next Reminder")
                                    .font(.body)
                                Spacer()
                                Text(nextNotificationDate, style: .time)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Learning Tips Section
                Section(header: Text("LEARNING")) {
                    VerbsSettingsRow(
                        icon: "lightbulb.fill",
                        iconColor: .appRed,
                        title: "Learning Tips",
                        description: "Effective learning strategies"
                    ) { showingLearningTips = true }
                }

                // Clear Data Section
                Section(header: Text("CLEAR DATA")) {
                    VerbsSettingsRow(
                        icon: "trash.fill",
                        iconColor: .appRed,
                        title: "Clear Tests",
                        description: "Delete all saved tests"
                    ) { showingClearTestsAlert = true }

                    VerbsSettingsRow(
                        icon: "heart.slash.fill",
                        iconColor: .appRed,
                        title: "Clear Favorites",
                        description: "Remove all favorited verbs"
                    ) { showingClearFavoritesAlert = true }
                }

                // Support Section
                Section(header: Text("SUPPORT")) {
                    VerbsSettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .appRed,
                        title: "Help & Support",
                        description: "Get help and contact support"
                    ) { showingHelpSupport = true }

                    VerbsSettingsRow(
                        icon: "lock.fill",
                        iconColor: .appRed,
                        title: "Terms & Privacy",
                        description: "View terms and privacy policy"
                    ) { showingTermsPrivacy = true }

                    VerbsSettingsRow(
                        icon: "info.circle.fill",
                        iconColor: .appRed,
                        title: "About",
                        description: "App version and information"
                    ) { showingAbout = true }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SplitTitleView("Settings", splitIndex: 4)
                }
            }
            .onAppear {
                isReminderEnabled = notificationManager.isScheduled
                if notificationManager.isScheduled {
                    selectedTime = notificationManager.scheduledTime ?? Date()
                }
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { isReminderEnabled = false }
            } message: {
                Text("Please enable notifications in Settings to receive daily learning reminders.")
            }
            .alert("Are you sure?", isPresented: $showingClearTestsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) { testManager.clearAllTests() }
            } message: {
                Text("This will permanently delete all your tests. This action cannot be undone.")
            }
            .alert("Are you sure?", isPresented: $showingClearFavoritesAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) { favoriteManager.clearAllFavorites() }
            } message: {
                Text("This will permanently delete all your favorites. This action cannot be undone.")
            }
            .sheet(isPresented: $showingHelpSupport) { VerbsHelpSupportView() }
            .sheet(isPresented: $showingTermsPrivacy) { VerbsTermsPrivacyView() }
            .sheet(isPresented: $showingAbout) { VerbsAboutView() }
            .sheet(isPresented: $showingLearningTips) { VerbsLearningTipsView() }
        }
        .navigationViewStyle(.stack)
    }

    private func requestNotificationPermission() {
        notificationManager.requestAuthorization { granted in
            if granted { scheduleNotification() }
            else {
                DispatchQueue.main.async {
                    showingPermissionAlert = true
                    isReminderEnabled = false
                }
            }
        }
    }

    private func scheduleNotification() {
        notificationManager.scheduleDailyReminder(at: selectedTime)
    }
}

struct VerbsSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(iconColor.opacity(0.8)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                .frame(width: 8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VerbsSettingsView()
}
