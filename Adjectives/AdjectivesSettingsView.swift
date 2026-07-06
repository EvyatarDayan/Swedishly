//
//  AdjectivesSettingsView.swift
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-01-28.
//

import SwiftUI

struct AdjectivesSettingsView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @StateObject private var testHistoryManager = AdjectivesTestHistoryManager.shared
    @StateObject private var practiceHistoryManager = AdjectivesPracticeHistoryManager.shared
    @StateObject private var notificationManager = AdjectivesNotificationManager.shared
    @State private var showingClearHistoryAlert = false
    @State private var showingNotificationSettings = false
    @State private var showingLearningTips = false
    @State private var showingTermsPrivacy = false
    @State private var showingHelpSupport = false
    @State private var showingAbout = false
    
    private var notificationSubtitle: String {
        if notificationManager.notificationsEnabled {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: notificationManager.notificationTime)
            return "Every day at \(timeString)"
        } else {
            return "Configure notification time"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Spacer()
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appRed)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 5)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 0) {
                AdjectivesSettingsSection(header: "MODE") {
                    AdjectivesSettingsRow(
                        icon: "moon.fill",
                        iconColor: .appRed,
                        title: "Dark Mode",
                        subtitle: "Enable/Disable dark mode",
                        accessory: .toggle(isOn: $darkModeEnabled)
                    )
                }
                AdjectivesSettingsSection(header: "SCHEDULE") {
                    AdjectivesSettingsRow(
                        icon: "clock",
                        iconColor: .appRed,
                        title: "Schedule Notifications",
                        subtitle: notificationSubtitle,
                        accessory: .chevron(action: { showingNotificationSettings = true })
                    )
                }
                AdjectivesSettingsSection(header: "LEARNING") {
                    AdjectivesSettingsRow(
                        icon: "lightbulb.fill",
                        iconColor: .appRed,
                        title: "Learning Tips",
                        subtitle: "Effective learning strategies",
                        accessory: .chevron(action: { showingLearningTips = true })
                    )
                }
                AdjectivesSettingsSection(header: "SUPPORT") {
                    AdjectivesSettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .appRed,
                        title: "Help & Support",
                        subtitle: "Get help and contact support",
                        accessory: .chevron(action: { showingHelpSupport = true })
                    )
                    AdjectivesSettingsRow(
                        icon: "doc.text.fill",
                        iconColor: .appRed,
                        title: "Terms & Privacy",
                        subtitle: "View terms and privacy policy",
                        accessory: .chevron(action: { showingTermsPrivacy = true })
                    )
                    AdjectivesSettingsRow(
                        icon: "info.circle.fill",
                        iconColor: .appRed,
                        title: "About",
                        subtitle: "App version and information",
                        accessory: .chevron(action: { showingAbout = true })
                    )
                }
                AdjectivesSettingsSection(header: "CACHE") {
                    AdjectivesSettingsRow(
                        icon: "clock.arrow.circlepath",
                        iconColor: .appRed,
                        title: "Clear History",
                        subtitle: "Delete all history records",
                        accessory: .button(badge: nil, action: { showingClearHistoryAlert = true })
                    )
                }
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 55)
            }
        }
        .background(Color(.systemGroupedBackground))
        .clipped()
        .alert("Clear History", isPresented: $showingClearHistoryAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                testHistoryManager.clearAllHistory()
                practiceHistoryManager.clearAllHistory()
            }
        } message: {
            Text("Are you sure? This will delete all history records.")
        }
        .sheet(isPresented: $showingNotificationSettings) { AdjectivesNotificationSettingsModal() }
        .sheet(isPresented: $showingLearningTips) { AdjectivesLearningTipsView() }
        .sheet(isPresented: $showingTermsPrivacy) { AdjectivesTermsPrivacyView() }
        .sheet(isPresented: $showingHelpSupport) { AdjectivesHelpSupportView() }
        .sheet(isPresented: $showingAbout) { AdjectivesAboutView() }
    }
}

struct AdjectivesSettingsSection<Content: View>: View {
    let header: String
    let content: Content
    init(header: String, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
            VStack(spacing: 8) { content }
            .padding(.horizontal, 20)
        }
    }
}

enum AdjectivesSettingsRowAccessory {
    case toggle(isOn: Binding<Bool>)
    case chevron(action: (() -> Void)? = nil)
    case button(badge: String?, action: () -> Void)
}

struct AdjectivesSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let accessory: AdjectivesSettingsRowAccessory
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(.primary)
                Text(subtitle).font(.system(size: 13)).foregroundColor(.secondary)
            }
            Spacer()
            switch accessory {
            case .toggle(let isOn):
                Toggle("", isOn: isOn).labelsHidden()
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            case .button(let badge, _):
                HStack(spacing: 8) {
                    if let badge = badge, !badge.isEmpty {
                        Text(badge)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.red).cornerRadius(12)
                    }
                    Text("Clear").font(.system(size: 15, weight: .semibold)).foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12).shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            switch accessory {
            case .chevron(let action): if let action = action { action() }
            case .button(_, let action): action()
            case .toggle: break
            }
        }
    }
}

struct AdjectivesNotificationSettingsModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = AdjectivesNotificationManager.shared
    private var dailyReminderBinding: Binding<Bool> {
        Binding(
            get: { notificationManager.notificationsEnabled },
            set: { newValue in
                if newValue {
                    notificationManager.requestAuthorization { granted in
                        notificationManager.notificationsEnabled = granted
                    }
                } else {
                    notificationManager.notificationsEnabled = false
                }
            }
        )
    }
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Daily reminder", isOn: dailyReminderBinding)
                } header: { Text("Reminder") } footer: { Text("Get a daily notification to practice Swedish") }
                if notificationManager.notificationsEnabled {
                    Section {
                        DatePicker("Time", selection: $notificationManager.notificationTime, displayedComponents: .hourAndMinute)
                    } header: { Text("Notification time") }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Notifications")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appRed)
                }
                SettingsModalToolbarItem(placement: .navigationBarTrailing) {
                    SettingsModalPlainButton(title: "Done", action: { dismiss() })
                }
            }
        }
    }
}

struct AdjectivesLearningTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AdjectivesTipSection(number: "1", title: "Learn words inside a sentence (not alone)", description: "Your brain remembers meaning + situation, not lists.", badExample: "äta = to eat", goodExample: "Jag äter frukost.\n\"I eat breakfast.\"", betterExample: "Even better:\nJag äter frukost varje morgon.")
                    AdjectivesTipSection(number: "2", title: "Use active recall, not rereading", description: "Reading feels productive, but testing yourself works better.", simpleMethod: "Simple method:\n• Look at the word\n• Hide it\n• Ask yourself: \"What does this mean?\"\n• Check\n\n30 seconds per word is enough.")
                    AdjectivesTipSection(number: "3", title: "Short, frequent sessions (5–10 min)", description: "The brain forgets fast — and that's normal.", bestSchedule: "Best schedule:\n• 5–10 minutes\n• 1–3 times per day\n• Stop before you feel tired\n\nConsistency > duration.")
                    AdjectivesTipSection(number: "4", title: "Say it out loud (even quietly)", description: "Speaking activates memory differently than reading.", justDo: "Just:\n• Say the word\n• Say the sentence\n• Say the translation\n\nYes, even if your pronunciation isn't perfect.")
                    AdjectivesTipSection(number: "5", title: "Connect the word to you", description: "Personal relevance boosts memory.", insteadOf: "Instead of:\nHan äter middag.", tryThis: "Try:\nJag äter middag klockan sex.\n\nYour brain cares more when you are in the sentence.")
                    AdjectivesTipSection(number: "6", title: "Use spaced repetition (but keep it simple)", description: "You don't need fancy systems.", justReview: "Just review:\n• same day\n• next day\n• 3 days later\n• 1 week later\n\nEven 10 words reviewed beats 50 new ones forgotten.")
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What NOT to do").font(.title3).fontWeight(.bold).foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Don't memorize long word lists")
                            Text("• Don't cram for an hour")
                            Text("• Don't rely only on passive reading")
                            Text("• Don't worry about perfection")
                        }.font(.body).foregroundColor(.primary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .cornerRadius(12).shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The simplest winning routine (5 minutes)").font(.title3).fontWeight(.bold).foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Pick 5 words")
                            Text("• Read each in a sentence")
                            Text("• Say each out loud once")
                            Text("• Test yourself quickly")
                            Text("• Stop")
                        }.font(.body).foregroundColor(.primary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .cornerRadius(12).shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }.padding(.horizontal, 20).padding(.vertical, 20)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Learning Tips")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appRed)
                }
                SettingsModalToolbarItem(placement: .navigationBarTrailing) {
                    SettingsModalPlainButton(title: "Done", action: { dismiss() })
                }
            }
        }
    }
}

struct AdjectivesTipSection: View {
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
            Text(number).font(.title2).fontWeight(.bold).foregroundColor(.appRed).frame(width: 30)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline).fontWeight(.semibold).foregroundColor(.primary)
                Text(description).font(.body).foregroundColor(.secondary)
                if let badExample = badExample, let goodExample = goodExample {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("❌").font(.title3)
                            Text("Bad").font(.subheadline).fontWeight(.semibold).foregroundColor(.red)
                        }
                        Text(badExample).font(.body).foregroundColor(.primary)
                        HStack(alignment: .top, spacing: 8) {
                            Text("✅").font(.title3)
                            Text("Good").font(.subheadline).fontWeight(.semibold).foregroundColor(.green)
                        }
                        Text(goodExample).font(.body).foregroundColor(.primary)
                        if let betterExample = betterExample {
                            Text(betterExample).font(.body).foregroundColor(.primary).padding(.top, 4)
                        }
                    }.padding(.top, 4)
                }
                if let simpleMethod = simpleMethod { Text(simpleMethod).font(.body).foregroundColor(.primary).padding(.top, 4) }
                if let bestSchedule = bestSchedule { Text(bestSchedule).font(.body).foregroundColor(.primary).padding(.top, 4) }
                if let justDo = justDo { Text(justDo).font(.body).foregroundColor(.primary).padding(.top, 4) }
                if let insteadOf = insteadOf, let tryThis = tryThis {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insteadOf).font(.body).foregroundColor(.primary)
                        Text(tryThis).font(.body).foregroundColor(.primary)
                    }.padding(.top, 4)
                }
                if let justReview = justReview { Text(justReview).font(.body).foregroundColor(.primary).padding(.top, 4) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12).shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AdjectivesTermsPrivacyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Terms").tag(0)
                    Text("Privacy").tag(1)
                    Text("Disclaimer").tag(2)
                }.pickerStyle(.segmented).padding(.horizontal).padding(.top, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(contentText).font(.body).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                    }.padding().frame(maxWidth: .infinity, alignment: .leading)
                }
            }.background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Terms & Privacy")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appRed)
                }
                SettingsModalToolbarItem(placement: .navigationBarTrailing) {
                    SettingsModalPlainButton(title: "Done", action: { dismiss() })
                }
            }
        }
    }
    private var contentText: String {
        switch selectedTab {
        case 0: return termsContent
        case 1: return privacyContent
        default: return disclaimerContent
        }
    }
    private let termsContent = """
    TERMS OF USE - Last Updated: January 26, 2026
    Welcome to SWAdjective. These Terms of Use govern your access to and use of the SWAdjective mobile application. By using the App, you agree to be bound by these Terms. SWAdjective is a mobile application designed to help you practice Swedish adjectives. Contact us through the App's Help & Support section.
    """
    private let privacyContent = """
    PRIVACY POLICY - Last Updated: January 26, 2026
    At SWAdjective, we are committed to protecting your privacy. SWAdjective does not collect, transmit, or store any personal information on external servers. All data is stored locally on your device. Contact us through the App's Help & Support section.
    """
    private let disclaimerContent = """
    DISCLAIMER - SWAdjective is provided "as is" without warranties. Users are responsible for verifying information. The App is for educational purposes only. By using SWAdjective, you agree to this Disclaimer.
    """
}

struct AdjectivesHelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showForm = false
    @State private var showError = false
    @State private var alertType: AlertType = .none
    enum AlertType { case none, messageSent, callSupport }
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
                        Section(header: Text("Your full name")) { TextField("Full name", text: $fullName) }
                        Section(header: Text("Your Email")) { TextField("Email", text: $email).keyboardType(.emailAddress).autocapitalization(.none) }
                        Section(header: Text("Subject")) { TextField("", text: $subject) }
                        Section(header: Text("Description")) { TextEditor(text: $description).frame(height: 120) }
                        if showError && !allFieldsFilled { Section { Text("All fields are required.").foregroundColor(.red).font(.subheadline) } }
                        Section {
                            Button(action: {
                                if allFieldsFilled { alertType = .messageSent; showError = false } else { showError = true }
                            }) {
                                Text("Send").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50)
                                    .background(allFieldsFilled ? Color.green : Color.gray).cornerRadius(12)
                            }.disabled(!allFieldsFilled)
                        }.listRowBackground(Color.clear)
                    }
                } else {
                    VStack(spacing: 32) {
                        Text("We'd love to hear from you!").font(.title3).fontWeight(.bold)
                        Text("Email: abashelariprod@gmail.com").font(.subheadline)
                        Text("Website: https://abashelariprod.wordpress.com").font(.subheadline)
                        Button(action: { showForm = true }) {
                            Text("Contact form").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50).background(Color.green).cornerRadius(12).padding(.horizontal, 32)
                        }
                    }.padding(.vertical, 32)
                }
            }.background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SettingsModalToolbarItem(placement: .navigationBarTrailing) {
                    if showForm {
                        SettingsModalPlainButton(title: "Cancel", action: { showForm = false })
                    } else {
                        SettingsModalPlainButton(title: "Done", action: { dismiss() })
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(showForm ? "Contact us" : "Help & Support")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appRed)
                }
            }
            .alert(isPresented: Binding(get: { alertType != .none }, set: { if !$0 { alertType = .none } })) {
                switch alertType {
                case .messageSent: return Alert(title: Text("Message Sent"), message: Text("Thanks for reaching out!"), dismissButton: .default(Text("OK")) { dismiss() })
                case .callSupport: return Alert(title: Text("Call Support"), message: Text("Do you want to call \(supportPhone)?"), primaryButton: .default(Text("Yes")) { if let url = URL(string: "tel://" + supportPhone.filter { $0.isNumber }) { UIApplication.shared.open(url) } }, secondaryButton: .cancel(Text("No")))
                case .none: return Alert(title: Text(""), message: Text(""), dismissButton: .default(Text("")))
                }
            }
        }
    }
}

struct AdjectivesAboutView: View {
    @Environment(\.dismiss) private var dismiss
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(appVersion).font(.system(size: 16, weight: .medium)).foregroundColor(.secondary).frame(maxWidth: .infinity).padding(.top, 8)
                    Text("About SWAdjective").font(.title2).fontWeight(.bold)
                    Text("SWAdjective is a Swedish adjective practice app designed to help you master Swedish adjectives with ease. Practice adjective agreement, comparison, and antonyms. Track your progress and set daily reminders.").font(.body).multilineTextAlignment(.leading)
                    Text("About ABASHELARI").font(.title2).fontWeight(.bold)
                    Text("At ABASHELARI, we believe in creating software that makes everyday life simpler and more enjoyable. We develop innovative digital solutions that blend creativity with technology.").font(.body).multilineTextAlignment(.leading)
                }.padding()
            }.background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("About")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appRed)
                }
                SettingsModalToolbarItem(placement: .navigationBarTrailing) {
                    SettingsModalPlainButton(title: "Done", action: { dismiss() })
                }
            }
        }
    }
}

#Preview {
    AdjectivesSettingsView()
}
