//
//  SettingsView.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI
import UserNotifications

struct GrammarSettingsView: View {
    @ObservedObject var resultsManager: TestResultsManager
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("dailyReminder") private var dailyReminder = false
    @AppStorage("reminderHour") private var reminderHour: Int = 14
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    @State private var showAbout = false
    @State private var showPrivacy = false
    @State private var showLearningTips = false
    @State private var showHelp = false
    @State private var showClearHistory = false
    @State private var showReminderModal = false
    @State private var selectedTime = Date()
    @State private var nextReminderDate: Date? = nil
    
    init(resultsManager: TestResultsManager) {
        self.resultsManager = resultsManager
    }
    
    var body: some View {
        NavigationView {
            List {
                // MODE Section
                Section {
                    SettingsRow(
                        icon: "moon.fill",
                        iconColor: .appRed,
                        title: "Dark Mode",
                        subtitle: "Enable dark mode",
                        trailing: {
                            Toggle("", isOn: $darkMode)
                                .labelsHidden()
                        }
                    )
                } header: {
                    Text("MODE")
                }
                
                // SCHEDULE Section
                Section {
                    Button(action: { showReminderModal = true }) {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .appRed,
                            title: "Daily Reminder",
                            subtitle: dailyReminder ? "Notification set to \(formatTime(selectedTime))" : "Set learning reminder",
                            trailing: {
                                if dailyReminder {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 20))
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        )
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("SCHEDULE")
                }
                
                // LEARNING Section
                Section {
                    Button(action: { showLearningTips = true }) {
                        SettingsRow(
                            icon: "lightbulb.fill",
                            iconColor: .appRed,
                            title: "Learning Tips",
                            subtitle: "Effective learning strategies",
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        )
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("LEARNING")
                }
                
                // CLEAR DATA Section
                Section {
                    Button(action: { showClearHistory = true }) {
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: .appRed,
                            title: "Clear History",
                            subtitle: "Delete all saved tests",
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        )
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("CLEAR DATA")
                }
                
                // SUPPORT Section
                Section {
                    Button(action: { showHelp = true }) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .appRed,
                            title: "Help & Support",
                            subtitle: "Get help and contact support",
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: { showPrivacy = true }) {
                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: .appRed,
                            title: "Terms and Privacy",
                            subtitle: "Privacy policy and terms",
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: { showAbout = true }) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .appRed,
                            title: "About",
                            subtitle: "App version and information",
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        )
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("SUPPORT")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAbout) {
                GrammarAboutView()
            }
            .sheet(isPresented: $showPrivacy) {
                GrammarTermsPrivacyView()
            }
            .sheet(isPresented: $showLearningTips) {
                GrammarLearningTipsView()
            }
            .sheet(isPresented: $showHelp) {
                GrammarHelpSupportView()
            }
            .sheet(isPresented: $showReminderModal) {
                ReminderSettingsView(
                    isEnabled: $dailyReminder,
                    selectedTime: $selectedTime,
                    reminderHour: $reminderHour,
                    reminderMinute: $reminderMinute,
                    onSave: {
                        updateNextReminderDate()
                    }
                )
            }
            .alert("Clear History", isPresented: $showClearHistory) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    resultsManager.clearAllResults()
                }
            } message: {
                Text("Are you sure you want to delete all saved test results? This action cannot be undone.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Initialize selectedTime from stored values
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            if components.hour == 0 && components.minute == 0 {
                components.hour = 14
                components.minute = 0
            }
            selectedTime = calendar.date(from: components) ?? calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
            
            if dailyReminder {
                updateNextReminderDate()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    scheduleNotification()
                }
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Check authorization status
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                return
            }
            
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Practice!"
            content.body = "Don't forget to practice Swedish grammar today."
            content.sound = .default
            
            // Schedule daily notification
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        updateNextReminderDate()
                    }
                }
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        nextReminderDate = nil
    }
    
    private func updateNextReminderDate() {
        let calendar = Calendar.current
        
        // Get today's date with the selected time
        let today = Date()
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        todayComponents.hour = reminderHour
        todayComponents.minute = reminderMinute
        
        if let todayAtTime = calendar.date(from: todayComponents) {
            // If the time has passed today, schedule for tomorrow
            if todayAtTime <= today {
                nextReminderDate = calendar.date(byAdding: .day, value: 1, to: todayAtTime)
            } else {
                nextReminderDate = todayAtTime
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: () -> Trailing
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(.vertical, 4)
    }
}

struct GrammarLearningTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Tip 1
                    GrammarTipSection(
                        number: "1",
                        title: "Learn words inside a sentence (not alone)",
                        description: "Your brain remembers meaning + situation, not lists.",
                        badExample: "äta = to eat",
                        goodExample: "Jag äter frukost.\n\"I eat breakfast.\"",
                        betterExample: "Even better:\nJag äter frukost varje morgon."
                    )
                    
                    // Tip 2
                    GrammarTipSection(
                        number: "2",
                        title: "Use active recall, not rereading",
                        description: "Reading feels productive, but testing yourself works better.",
                        simpleMethod: "Simple method:\n• Look at the word\n• Hide it\n• Ask yourself: \"What does this mean?\"\n• Check\n\n30 seconds per word is enough."
                    )
                    
                    // Tip 3
                    GrammarTipSection(
                        number: "3",
                        title: "Short, frequent sessions (5–10 min)",
                        description: "The brain forgets fast — and that's normal.",
                        bestSchedule: "Best schedule:\n• 5–10 minutes\n• 1–3 times per day\n• Stop before you feel tired\n\nConsistency > duration."
                    )
                    
                    // Tip 4
                    GrammarTipSection(
                        number: "4",
                        title: "Say it out loud (even quietly)",
                        description: "Speaking activates memory differently than reading.",
                        justDo: "Just:\n• Say the word\n• Say the sentence\n• Say the translation\n\nYes, even if your pronunciation isn't perfect."
                    )
                    
                    // Tip 5
                    GrammarTipSection(
                        number: "5",
                        title: "Connect the word to you",
                        description: "Personal relevance boosts memory.",
                        insteadOf: "Instead of:\nHan äter middag.",
                        tryThis: "Try:\nJag äter middag klockan sex.\n\nYour brain cares more when you are in the sentence."
                    )
                    
                    // Tip 6
                    GrammarTipSection(
                        number: "6",
                        title: "Use spaced repetition (but keep it simple)",
                        description: "You don't need fancy systems.",
                        justReview: "Just review:\n• same day\n• next day\n• 3 days later\n• 1 week later\n\nEven 10 words reviewed beats 50 new ones forgotten."
                    )
                    
                    // What NOT to do
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What NOT to do")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Don't memorize long word lists")
                            Text("• Don't cram for an hour")
                            Text("• Don't rely only on passive reading")
                            Text("• Don't worry about perfection")
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Simplest winning routine
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The simplest winning routine (5 minutes)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Pick 5 words")
                            Text("• Read each in a sentence")
                            Text("• Say each out loud once")
                            Text("• Test yourself quickly")
                            Text("• Stop")
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Learning Tips")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GrammarTipSection: View {
    let number: String
    let title: String
    let description: String
    var badExample: String? = nil
    var goodExample: String? = nil
    var betterExample: String? = nil
    var simpleMethod: String? = nil
    var bestSchedule: String? = nil
    var justDo: String? = nil
    var insteadOf: String? = nil
    var tryThis: String? = nil
    var justReview: String? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if let badExample = badExample, let goodExample = goodExample {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("❌")
                                .font(.title3)
                            Text("Bad")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        Text(badExample)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("✅")
                                .font(.title3)
                            Text("Good")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        Text(goodExample)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        if let betterExample = betterExample {
                            Text(betterExample)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 4)
                }
                
                if let simpleMethod = simpleMethod {
                    Text(simpleMethod)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                
                if let bestSchedule = bestSchedule {
                    Text(bestSchedule)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                
                if let justDo = justDo {
                    Text(justDo)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                
                if let insteadOf = insteadOf, let tryThis = tryThis {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insteadOf)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text(tryThis)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 4)
                }
                
                if let justReview = justReview {
                    Text(justReview)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct GrammarHelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showForm = false
    @State private var showError = false
    @State private var showCallAlert = false
    @State private var alertType: AlertType = .none
    
    enum AlertType {
        case none
        case messageSent
        case callSupport
    }
    
    let supportPhone = "+46 123 456 789"
    
    var allFieldsFilled: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Group {
                if showForm {
                    Form {
                        Section(header: Text("Your full name")) {
                            TextField("Full name", text: $fullName)
                        }
                        
                        Section(header: Text("Your Email")) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        Section(header: Text("Subject")) {
                            TextField("", text: $subject)
                                .onChange(of: subject) { oldValue, newValue in
                                    if newValue.count > 100 {
                                        subject = String(newValue.prefix(100))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(subject.count)/100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section(header: Text("Description")) {
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .onChange(of: description) { oldValue, newValue in
                                    if newValue.count > 400 {
                                        description = String(newValue.prefix(400))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(description.count)/400")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showError && !allFieldsFilled {
                            Section {
                                Text("All fields are required.")
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }
                        }
                        
                        Section {
                            Button(action: {
                                if allFieldsFilled {
                                    alertType = .messageSent
                                    showError = false
                                } else {
                                    showError = true
                                }
                            }) {
                                Text("Send")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(allFieldsFilled ? Color.green : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!allFieldsFilled)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Contact us")
                                .font(.headline)
                        }
                    }
                } else {
                    VStack {
                        Spacer(minLength: 0)
                        VStack(alignment: .center, spacing: 32) {
                            VStack(alignment: .center, spacing: 16) {
                                Text("We'd love to hear from you!")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text("Whether you have questions,")
                                    .font(.body)
                                
                                Text("feedback, or just want to say hi,")
                                    .font(.body)
                                
                                Text("feel free to reach out.")
                                    .font(.body)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                                    .padding(.bottom, 32)
                                
                                Text("Email: abashelariprod@gmail.com")
                                    .font(.subheadline)
                                
                                Text("Website: https://abashelariprod.wordpress.com")
                                    .font(.subheadline)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)
                            
                            Text("OR")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                            
                            Button(action: {
                                showForm = true
                            }) {
                                Text("Contact form")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 32)
                            }
                            
                            Text("We aim to respond within 24 hours.")
                                .font(.body)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.vertical, 32)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Help and support")
                                .font(.headline)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showForm {
                        Button("Cancel") {
                            showForm = false
                        }
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .alert(isPresented: Binding(
                get: { alertType != .none },
                set: { if !$0 { alertType = .none } }
            )) {
                switch alertType {
                case .messageSent:
                    return Alert(
                        title: Text("Message Sent"),
                        message: Text("Thanks for reaching out!"),
                        dismissButton: .default(Text("OK")) {
                            dismiss()
                        }
                    )
                case .callSupport:
                    return Alert(
                        title: Text("Call Support"),
                        message: Text("Do you want to call \(supportPhone)?"),
                        primaryButton: .default(Text("Yes")) {
                            if let url = URL(string: "tel://" + supportPhone.filter { $0.isNumber }) {
                                UIApplication.shared.open(url)
                            }
                        },
                        secondaryButton: .cancel(Text("No"))
                    )
                case .none:
                    return Alert(title: Text(""), message: Text(""), dismissButton: .default(Text("")))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct GrammarAboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Version
                    VStack(alignment: .center, spacing: 4) {
                        Text("Version")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(appVersion)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // About SWGrammar Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About SWGrammar")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("SWGrammar is a comprehensive Swedish grammar learning app designed to help you master Swedish grammar with ease. Practice verb conjugations, learn personal pronouns, test your knowledge with interactive quizzes, and track your progress. Learn grammar rules with accurate translations and example sentences. Never miss a learning opportunity again.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // About ABASHELARI Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About ABASHELARI")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("At ABASHELARI, we believe in creating software that makes everyday life simpler, smarter, and more enjoyable. Our mission is to develop innovative digital solutions that blend creativity with technology, offering users tools that are intuitive, reliable, and engaging.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Text("Whether it's educational apps, lifestyle tools, or entertainment experiences, ABASHELARI is dedicated to delivering high-quality products that inspire learning, spark curiosity, and bring value to people around the world.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Text("Driven by passion and guided by innovation, ABASHELARI is committed to continuous improvement and to building software that connects people with what matters most.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("About")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct GrammarTermsPrivacyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Section", selection: $selectedTab) {
                    Text("Terms").tag(0)
                    Text("Privacy").tag(1)
                    Text("Disclaimer").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(contentText)
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Terms & Privacy")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var contentText: String {
        switch selectedTab {
        case 0:
            return termsContent
        case 1:
            return privacyContent
        default:
            return disclaimerContent
        }
    }
    
    private let termsContent = """
    TERMS OF USE
    
    Last Updated: January 5, 2026
    
    Welcome to SWGrammar. These Terms of Use ("Terms") govern your access to and use of the SWGrammar mobile application ("App"). By using the App, you agree to be bound by these Terms.
    
    1. ACCEPTANCE OF TERMS
    By downloading, installing, or using SWGrammar, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy.
    
    2. DESCRIPTION OF SERVICE
    SWGrammar is a mobile application designed to help users learn Swedish grammar. The App allows users to:
    - Practice Swedish verb conjugations
    - Learn personal pronouns
    - Test knowledge with interactive quizzes
    - Track learning progress through test results
    - Review test history and scores
    
    3. USER ACCOUNTS
    You may use the App without creating an account. All data is stored locally on your device.
    
    4. ACCEPTABLE USE
    You agree to use the App only for lawful purposes and in accordance with these Terms. You agree not to:
    - Use the App for any illegal or unauthorized purpose
    - Attempt to gain unauthorized access to any part of the App
    - Interfere with or disrupt the App's functionality
    - Use automated systems to access the App
    
    5. INTELLECTUAL PROPERTY
    The App and its content, including but not limited to text, graphics, logos, and software, are the property of SWGrammar and are protected by copyright and other intellectual property laws.
    
    6. LIMITATION OF LIABILITY
    SWGrammar is provided "as is" without warranties of any kind. We do not guarantee that the App will be error-free or uninterrupted. In no event shall SWGrammar be liable for any indirect, incidental, or consequential damages.
    
    7. MODIFICATIONS TO TERMS
    We reserve the right to modify these Terms at any time. Your continued use of the App after any changes constitutes acceptance of the modified Terms.
    
    8. CONTACT INFORMATION
    If you have any questions about these Terms, please contact us through the App's support section.
    """
    
    private let privacyContent = """
    PRIVACY POLICY
    
    Last Updated: January 5, 2026
    
    At SWGrammar, we are committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our mobile application.
    
    1. NO DATA COLLECTION
    SWGrammar does not collect, transmit, or store any of your personal information on external servers. We do not collect:
    - Usage analytics
    - Device information
    - Location data
    - Any other personal data
    
    All information you enter into the App remains on your device only.
    
    2. LOCAL DATA STORAGE
    All your data is stored exclusively on your device using secure local storage methods. This includes:
    - Test results and scores
    - Test history
    - App settings and preferences
    
    Your data never leaves your device and is not transmitted to any external servers or third parties.
    
    3. DATA MANAGEMENT
    You have full control over your data:
    - Clear History: In Settings, you can use the "Clear History" option to remove all test results. This action cannot be undone.
    These actions are permanent and cannot be reversed.
    
    4. NO DATA SHARING
    Since we do not collect any data, we do not and cannot share your information with anyone. Your privacy is fully protected because your data never leaves your device.
    
    5. DATA SECURITY
    Your data is protected by your device's built-in security features. We use secure local storage methods provided by iOS to ensure your information remains private and secure on your device.
    
    6. YOUR RIGHTS
    You have complete control over your data:
    - All data is stored locally on your device
    - You can clear all data at any time through Settings
    - No external parties have access to your information
    
    7. CHILDREN'S PRIVACY
    Our App is suitable for users of all ages. Since we do not collect any data, we do not collect personal information from anyone, including children.
    
    8. CHANGES TO THIS POLICY
    We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App.
    
    9. CONTACT US
    If you have any questions about this Privacy Policy, please contact us through the App's support section.
    """
    
    private let disclaimerContent = """
    DISCLAIMER
    
    Last Updated: January 5, 2026
    
    1. NO WARRANTY
    SWGrammar is provided "as is" and "as available" without any warranties, express or implied. We do not guarantee that the App will be error-free, uninterrupted, or free from defects.
    
    2. ACCURACY OF CONTENT
    While we strive to ensure accurate grammar rules, translations, and content, we cannot guarantee the accuracy of all translations and learning materials. Users are responsible for verifying information and should consult additional resources for comprehensive learning.
    
    3. LIMITATION OF LIABILITY
    To the fullest extent permitted by law, SWGrammar shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of data or use, arising out of or in connection with the use of the App.
    
    4. USER RESPONSIBILITY
    Users are solely responsible for:
    - The accuracy of information entered into the App
    - Verifying grammar rules and translations
    - Using the App as a supplementary learning tool
    - Maintaining the security of their device
    
    5. THIRD-PARTY SERVICES
    The App may integrate services such as text-to-speech for pronunciation. These are operated by third parties and are subject to their own terms of use and privacy policies.
    
    6. CHANGES TO THE APP
    We reserve the right to modify, suspend, or discontinue the App at any time without prior notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance.
    
    7. NO PROFESSIONAL ADVICE
    The App is for educational and learning purposes only. It does not constitute professional language instruction or certification. Users should consult with qualified language instructors for formal education.
    
    8. ACCEPTANCE
    By using SWGrammar, you acknowledge that you have read, understood, and agree to this Disclaimer.
    """
}

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isEnabled: Bool
    @Binding var selectedTime: Date
    @Binding var reminderHour: Int
    @Binding var reminderMinute: Int
    let onSave: () -> Void
    
    @State private var localSelectedTime: Date
    
    init(isEnabled: Binding<Bool>, selectedTime: Binding<Date>, reminderHour: Binding<Int>, reminderMinute: Binding<Int>, onSave: @escaping () -> Void) {
        self._isEnabled = isEnabled
        self._selectedTime = selectedTime
        self._reminderHour = reminderHour
        self._reminderMinute = reminderMinute
        self.onSave = onSave
        
        // Initialize local time from stored values
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = reminderHour.wrappedValue
        components.minute = reminderMinute.wrappedValue
        if components.hour == 0 && components.minute == 0 {
            components.hour = 14
            components.minute = 0
        }
        _localSelectedTime = State(initialValue: calendar.date(from: components) ?? calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Daily Reminder", isOn: $isEnabled)
                } header: {
                    Text("NOTIFICATION")
                } footer: {
                    Text("Get a daily reminder to practice Swedish grammar")
                }
                
                if isEnabled {
                    Section {
                        DatePicker("Time", selection: $localSelectedTime, displayedComponents: .hourAndMinute)
                    } header: {
                        Text("TIME")
                    }
                }
            }
            .navigationTitle("Daily Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Update the bindings
                        let calendar = Calendar.current
                        reminderHour = calendar.component(.hour, from: localSelectedTime)
                        reminderMinute = calendar.component(.minute, from: localSelectedTime)
                        selectedTime = localSelectedTime
                        
                        // Request notification permission if enabling
                        if isEnabled {
                            requestNotificationPermission()
                        } else {
                            cancelNotifications()
                        }
                        
                        onSave()
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    scheduleNotification()
                }
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Check authorization status
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                return
            }
            
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Practice!"
            content.body = "Don't forget to practice Swedish grammar today."
            content.sound = .default
            
            // Schedule daily notification
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

#Preview {
    GrammarSettingsView(resultsManager: TestResultsManager())
}
