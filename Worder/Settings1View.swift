//
//  WorderSettingsView.swift  <- RENAME THIS FILE on disk to "WorderSettingsView.swift" to fix build.
//  Swedishly
//
//  Created by EVYATAR DAYAN on 2026-02-01.
//

import SwiftUI
import Combine
import UserNotifications

// MARK: - Notification Manager (Worder – prefixed to avoid conflict)
class WorderNotificationManager: ObservableObject {
    static let shared = WorderNotificationManager()
    
    @Published var notificationsEnabled: Bool = false
    @Published var notificationTime: Date = {
        var components = DateComponents()   
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}

// MARK: - History Session Type (for filtering)
enum WorderHistorySessionType: String, Codable, CaseIterable {
    case wordOrder = "Word Order"
    case test = "Test"
}

// MARK: - Word Order History Item
/// Result for a single question within a practice session.
struct WorderQuestionResult: Codable {
    let exampleID: Int
    let correct: Bool
    let userAnswer: String
}

struct WordOrderHistoryItem: Identifiable, Codable {
    let id: UUID
    let dateTaken: Date
    let questions: Int
    let correct: Int
    /// Optional list of example IDs used in this session (nil for older items)
    let exampleIDs: [Int]?
    /// Optional per-question results preserving the order of the session
    let questionResults: [WorderQuestionResult]?
    /// Session type for history filter; nil = old item, treat as wordOrder.
    let sessionType: WorderHistorySessionType?
    
    init(id: UUID = UUID(), dateTaken: Date, questions: Int, correct: Int, exampleIDs: [Int]? = nil, questionResults: [WorderQuestionResult]? = nil, sessionType: WorderHistorySessionType? = .wordOrder) {
        self.id = id
        self.dateTaken = dateTaken
        self.questions = questions
        self.correct = correct
        self.exampleIDs = exampleIDs
        self.questionResults = questionResults
        self.sessionType = sessionType
    }
    
    var effectiveType: WorderHistorySessionType { 
        if let type = sessionType {
            return type
        }
        // Legacy items without sessionType default to wordOrder
        return .wordOrder
    }
    var wrong: Int { questions - correct }
    var percentage: Int { questions > 0 ? Int((Double(correct) / Double(questions)) * 100) : 0 }
}

// MARK: - Practice History Manager (Worder)
class WorderPracticeHistoryManager: ObservableObject {
    static let shared = WorderPracticeHistoryManager()
    
    @Published private(set) var historyItems: [WordOrderHistoryItem] = []
    
    private let storageKey = "worderPracticeHistory"
    
    private init() {
        loadHistory()
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WordOrderHistoryItem].self, from: data) else { return }
        historyItems = decoded
    }
    
    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(historyItems) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    func deleteHistoryItem(_ item: WordOrderHistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    /// Adds a session to history. By default inserts at the top; set `insertAtTop` to false to append.
    func addSession(questions: Int, correct: Int, exampleIDs: [Int]? = nil, questionResults: [WorderQuestionResult]? = nil, sessionType: WorderHistorySessionType = .wordOrder, insertAtTop: Bool = true) {
        let item = WordOrderHistoryItem(
            dateTaken: Date(),
            questions: questions,
            correct: correct,
            exampleIDs: exampleIDs,
            questionResults: questionResults,
            sessionType: sessionType
        )
        // Logging for debugging: show what we save to history
        print("[WorderPracticeHistoryManager] addSession -> questions:\(questions) correct:\(correct) exampleIDsCount:\(exampleIDs?.count ?? 0) questionResultsCount:\(questionResults?.count ?? 0)")
        if let qr = questionResults {
            for (i, q) in qr.enumerated() {
                print("[WorderPracticeHistoryManager] questionResult[\(i)]: exampleID=\(q.exampleID) correct=\(q.correct) userAnswer='\(q.userAnswer)'")
            }
        }
        if insertAtTop {
        historyItems.insert(item, at: 0)
        } else {
            historyItems.append(item)
        }
        saveHistory()
    }
    
    /// Returns sets of example IDs categorized by most recent correctness.
    /// Latest history entries take precedence when determining an example's latest status.
    func getPerformanceSets() -> (correct: Set<Int>, wrong: Set<Int>, answered: Set<Int>) {
        var latest: [Int: Bool] = [:] // exampleID -> correct
        for item in historyItems {
            guard let results = item.questionResults else { continue }
            // Iterate results in order (they represent the session order) but historyItems are newest-first,
            // so only set if not already set (we want the newest session result).
            for res in results {
                if latest[res.exampleID] == nil {
                    latest[res.exampleID] = res.correct
                }
            }
        }
        var correctSet: Set<Int> = []
        var wrongSet: Set<Int> = []
        for (id, correct) in latest {
            if correct { correctSet.insert(id) } else { wrongSet.insert(id) }
        }
        let answered = correctSet.union(wrongSet)
        return (correct: correctSet, wrong: wrongSet, answered: answered)
    }

    /// Generate a session's example IDs following distribution:
    /// 20% from wrong, 10% from correct, 70% from the rest (random).
    /// `availableIDs` restricts the pool (e.g., for filtered datasets).
    func generateSessionExampleIDs(total: Int, availableIDs: [Int]? = nil) -> [Int] {
        let allExamples = WordOrderDataManager.shared.getAllExamples().map { $0.id }
        let pool = Set(availableIDs ?? allExamples)
        let perf = getPerformanceSets()
        let wrongCandidates = Array(perf.wrong.intersection(pool))
        let correctCandidates = Array(perf.correct.intersection(pool))
        let answered = perf.answered.intersection(pool)
        let restCandidates = Array(pool.subtracting(answered))

        // Calculate counts
        let wrongCount = Int(round(Double(total) * 0.20))
        let correctCount = Int(round(Double(total) * 0.10))
        var restCount = total - wrongCount - correctCount
        if restCount < 0 { restCount = 0 }

        // Group constraints:
        // - Basic group: at most 20% of total
        // - Ensure at least 20% from each of these groups: bisats_biff, v2_practice, v2_pro
        let allExamplesFull = WordOrderDataManager.shared.getAllExamples()
        func groupOf(_ id: Int) -> String {
            return allExamplesFull.first(where: { $0.id == id })?.group?.lowercased() ?? ""
        }

        let requiredGroups = ["bisats_biff", "v2_practice", "v2_pro"]
        let basicGroupName = "basic"
        let minPerRequired = Int(ceil(Double(total) * 0.20))
        let maxBasic = Int(floor(Double(total) * 0.20))

        var selectedSet = Set<Int>()
        var basicCount = 0

        // Helper to pick up to n ids from a candidate list while respecting basic cap and excluding already selected.
        func pick(from candidates: [Int], upTo n: Int) -> [Int] {
            var out: [Int] = []
            for id in candidates.shuffled() {
                if out.count >= n { break }
                if selectedSet.contains(id) { continue }
                let g = groupOf(id)
                if g == basicGroupName && basicCount >= maxBasic { continue }
                out.append(id)
                selectedSet.insert(id)
                if g == basicGroupName { basicCount += 1 }
            }
            return out
        }

        // 1) Ensure minima for required groups
        for rg in requiredGroups {
            let groupCandidates = Array(pool.filter { groupOf($0) == rg })
            let picked = pick(from: groupCandidates, upTo: minPerRequired)
            // if not enough candidates, we pick what we can
            // continue
        }

        // 2) Reserve up to maxBasic from Basic group (do not exceed)
        let basicCandidates = Array(pool.filter { groupOf($0) == basicGroupName })
        let _ = pick(from: basicCandidates, upTo: maxBasic)

        // 3) Performance-aware remaining selection
        var selectedList: [Int] = Array(selectedSet)
        let selectedWrongCount = selectedList.filter { perf.wrong.contains($0) }.count
        let selectedCorrectCount = selectedList.filter { perf.correct.contains($0) }.count

        let wrongRem = max(0, wrongCount - selectedWrongCount)
        let correctRem = max(0, correctCount - selectedCorrectCount)
        var remaining = total - selectedList.count
        // pick wrongRem
        let wrongPick = pick(from: wrongCandidates, upTo: wrongRem)
        selectedList.append(contentsOf: wrongPick)
        // pick correctRem
        let correctPick = pick(from: correctCandidates, upTo: correctRem)
        selectedList.append(contentsOf: correctPick)
        remaining = total - selectedList.count

        // pick rest from restCandidates first
        if remaining > 0 {
            let restPick = pick(from: restCandidates, upTo: remaining)
            selectedList.append(contentsOf: restPick)
            remaining = total - selectedList.count
        }

        // fill any remaining from any pool members not yet selected
        if remaining > 0 {
            var remainingPool = Array(pool.subtracting(Set(selectedList)))
            // try to respect basic cap when picking
            remainingPool.shuffle()
            for id in remainingPool {
                if selectedList.count >= total { break }
                let g = groupOf(id)
                if g == basicGroupName && basicCount >= maxBasic { continue }
                selectedList.append(id)
                if g == basicGroupName { basicCount += 1 }
            }
        }

        // Ensure we don't exceed total
        if selectedList.count > total {
            selectedList = Array(selectedList.prefix(total))
        }

        // Final shuffle so order isn't predictable
        return selectedList.shuffled()
    }
    
    func clearAllHistory() {
        historyItems = []
        saveHistory()
    }
}

// MARK: - Settings View (Worder)
struct WorderSettingsView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @StateObject private var practiceHistoryManager = WorderPracticeHistoryManager.shared
    @StateObject private var notificationManager = WorderNotificationManager.shared
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
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 5)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 0) {
                    WorderSettingsSection(header: "MODE") {
                        WorderSettingsRow(
                            icon: "moon.fill",
                            iconColor: .purple,
                            title: "Dark Mode",
                            subtitle: "Enable/Disable dark mode",
                            accessory: .toggle(isOn: $darkModeEnabled)
                        )
                    }
                    
                    WorderSettingsSection(header: "SCHEDULE") {
                        WorderSettingsRow(
                            icon: "clock",
                            iconColor: .orange,
                            title: "Schedule Notifications",
                            subtitle: notificationSubtitle,
                            accessory: .chevron(action: {
                                showingNotificationSettings = true
                            })
                        )
                    }
                    
                    WorderSettingsSection(header: "LEARNING") {
                        WorderSettingsRow(
                            icon: "lightbulb.fill",
                            iconColor: .yellow,
                            title: "Learning Tips",
                            subtitle: "Effective learning strategies",
                            accessory: .chevron(action: {
                                showingLearningTips = true
                            })
                        )
                    }
                    
                    WorderSettingsSection(header: "SUPPORT") {
                        WorderSettingsRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "Help & Support",
                            subtitle: "Get help and contact support",
                            accessory: .chevron(action: {
                                showingHelpSupport = true
                            })
                        )
                        
                        WorderSettingsRow(
                            icon: "doc.text.fill",
                            iconColor: .blue,
                            title: "Terms & Privacy",
                            subtitle: "View terms and privacy policy",
                            accessory: .chevron(action: {
                                showingTermsPrivacy = true
                            })
                        )
                        
                        WorderSettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .blue,
                            title: "About",
                            subtitle: "App version and information",
                            accessory: .chevron(action: {
                                showingAbout = true
                            })
                        )
                    }
                    
                    WorderSettingsSection(header: "CACHE") {
                        WorderSettingsRow(
                            icon: "clock.arrow.circlepath",
                            iconColor: .red,
                            title: "Clear History",
                            subtitle: "Delete all history records",
                            accessory: .button(
                                badge: nil,
                                action: {
                                    showingClearHistoryAlert = true
                                }
                            )
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
                practiceHistoryManager.clearAllHistory()
            }
        } message: {
            Text("Are you sure? This will delete all history records.")
        }
        .sheet(isPresented: $showingNotificationSettings) {
            WorderNotificationSettingsModal()
        }
        .sheet(isPresented: $showingLearningTips) {
            WorderLearningTipsView()
        }
        .sheet(isPresented: $showingTermsPrivacy) {
            WorderTermsPrivacyView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            WorderHelpSupportView()
        }
        .sheet(isPresented: $showingAbout) {
            WorderAboutView()
        }
    }
}

// MARK: - Settings Section (Worder)
struct WorderSettingsSection<Content: View>: View {
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
            
            VStack(spacing: 8) {
                content
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Settings Row Accessory (Worder)
enum WorderSettingsRowAccessory {
    case toggle(isOn: Binding<Bool>)
    case chevron(action: (() -> Void)? = nil)
    case button(badge: String?, action: () -> Void)
}

// MARK: - Settings Row (Worder)
struct WorderSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let accessory: WorderSettingsRowAccessory
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            switch accessory {
            case .toggle(let isOn):
                Toggle("", isOn: isOn)
                    .labelsHidden()
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    Text("Clear")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            switch accessory {
            case .chevron(let action):
                if let action = action {
                    action()
                }
            case .button(_, let action):
                action()
            case .toggle:
                break
            }
        }
    }
}

// MARK: - Notification Settings Modal (Worder)
struct WorderNotificationSettingsModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = WorderNotificationManager.shared
    
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
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("Get a daily notification to practice Swedish")
                }
                
                if notificationManager.notificationsEnabled {
                    Section {
                        DatePicker("Time", selection: $notificationManager.notificationTime, displayedComponents: .hourAndMinute)
                    } header: {
                        Text("Notification time")
                    }
                }
            }
            .navigationTitle("Notifications")
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
}

// MARK: - Learning Tips View (Swedish Word Order: V2 Rule)
struct WorderLearningTipsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title & intro
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Swedish Word Order: The V2 Rule")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("In Swedish, the Verb is the anchor of the sentence. It must always be the second element.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // 1. The Basic Start
                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. The Basic Start")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("When you start with the person (Subject), it looks just like English.")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("Subject + VERB + Rest")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Text("Jag + läser + en bok. (I am reading a book.)")
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
                    
                    // 2. The "Switch" (V2 Rule)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("2. The \"Switch\" (V2 Rule)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("If you start with a Time (Today, Now) or Place (Here, In Sweden), the verb stays in spot #2. This pushes the Subject to spot #3.")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("Time/Place + VERB + Subject + Rest")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Text("Nu + läser + jag + en bok. (Now am reading I a book.)")
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
                    
                    // 3. Adding "Inte" (Not)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("3. Adding \"Inte\" (Not)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("To make a sentence negative, put inte directly after the verb.")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("Subject + VERB + inte")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Text("Jag + läser + inte. (I do not read.)")
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
                    
//                    // Quick Tips
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Quick Tips:")
//                            .font(.title3)
//                            .fontWeight(.bold)
//                            .foregroundColor(.primary)
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("• Verb is King: It always takes the 2nd position in statements.")
//                            Text("• The Swap: If \"Today\" comes first, \"I\" must move after the verb.")
//                            Text("• Simple Negation: Just add \"inte\" after the action.")
//                        }
//                        .font(.body)
//                        .foregroundColor(.primary)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(16)
//                    .background(
//                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
//                    )
//                    .cornerRadius(12)
//                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // The simplest way to think about it
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Here is the simplest way to think about it:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // 1. The Standard Way (S-V-O)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. The Standard Way (S-V-O)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("Just like in English, most simple sentences start with the Person (Subject).")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("1. Subject  2. Verb  3. Rest")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("Jag (I) - dricker (drink) - kaffe (coffee).")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("Han (He) - läser (reads) - en bok (a book).")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Divider()
                        
                        // 2. The "Swedish Rule" (V2)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("2. The \"Swedish Rule\" (The V2 Rule)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("In Swedish, if you start the sentence with Time or Place instead of the person, the Verb must still stay in the second spot. This \"pushes\" the person to the third spot.")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("1. Time/Place  2. Verb  3. Subject  4. Rest")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("Nu (Now) - dricker - jag - kaffe.")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("Här (Here) - läser - hon - boken.")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("Idag (Today) - är - jag - glad (happy).")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Divider()
                        
                        // 3. Adding "Inte" (Not)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3. Adding \"Inte\" (Not)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("In a normal sentence, put inte directly after the verb.")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("English: I do not eat.")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("Swedish: Jag äter inte. (Literal: I eat not.)")
                                .font(.body)
                                .foregroundColor(.primary)
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
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Learning Tips")
                        .font(.headline)
                        .fontWeight(.semibold)
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

// MARK: - Tip Section (Worder)
struct WorderTipSection: View {
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

// MARK: - Terms & Privacy View (Worder)
struct WorderTermsPrivacyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Terms").tag(0)
                    Text("Privacy").tag(1)
                    Text("Disclaimer").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
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
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
    
    Last Updated: February 1, 2026
    
    Welcome to SWWorder. These Terms of Use ("Terms") govern your access to and use of the SWWorder mobile application ("App"). By using the App, you agree to be bound by these Terms.
    
    1. ACCEPTANCE OF TERMS
    By downloading, installing, or using SWWorder, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy.
    
    2. DESCRIPTION OF SERVICE
    SWWorder is a mobile application designed to help you practice Swedish word order. The App allows you to:
    - Practice word order with sentence blocks (V2 rule, negation, questions, etc.)
    - Complete practice sessions and track your progress
    - View grammar tips and translations
    - Set daily reminders for practice
    
    3. USER ACCOUNTS
    You may use the App without creating an account. All data is stored locally on your device.
    
    4. ACCEPTABLE USE
    You agree to use the App only for lawful purposes and in accordance with these Terms. You agree not to:
    - Use the App for any illegal or unauthorized purpose
    - Attempt to gain unauthorized access to any part of the App
    - Interfere with or disrupt the App's functionality
    - Use automated systems to access the App
    
    5. INTELLECTUAL PROPERTY
    The App and its content, including but not limited to text, graphics, logos, and software, are the property of SWWorder and are protected by copyright and other intellectual property laws.
    
    6. LIMITATION OF LIABILITY
    SWWorder is provided "as is" without warranties of any kind. We do not guarantee that the App will be error-free or uninterrupted. In no event shall SWWorder be liable for any indirect, incidental, or consequential damages.
    
    7. MODIFICATIONS TO TERMS
    We reserve the right to modify these Terms at any time. Your continued use of the App after any changes constitutes acceptance of the modified Terms.
    
    8. CONTACT INFORMATION
    If you have any questions about these Terms, please contact us through the App's Help & Support section.
    """
    
    private let privacyContent = """
    PRIVACY POLICY
    
    Last Updated: February 1, 2026
    
    At SWWorder, we are committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our mobile application.
    
    1. NO DATA COLLECTION
    SWWorder does not collect, transmit, or store any of your personal information on external servers. We do not collect:
    - Usage analytics
    - Device information
    - Location data
    - Any other personal data
    
    All information you enter into the App remains on your device only.
    
    2. LOCAL DATA STORAGE
    All your data is stored exclusively on your device using secure local storage methods. This includes:
    - Practice history (word order sessions)
    - Session progress and results
    - App settings and preferences (e.g. dark mode, notification time)
    
    Your data never leaves your device and is not transmitted to any external servers or third parties.
    
    3. DATA MANAGEMENT
    You have full control over your data:
    - Clear History: In Settings, you can use the "Clear History" option to remove all practice history. This action cannot be undone.
    
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
    If you have any questions about this Privacy Policy, please contact us through the App's Help & Support section.
    """
    
    private let disclaimerContent = """
    DISCLAIMER
    
    Last Updated: February 1, 2026
    
    1. NO WARRANTY
    SWWorder is provided "as is" and "as available" without any warranties, express or implied. We do not guarantee that the App will be error-free, uninterrupted, or free from defects.
    
    2. ACCURACY OF CONTENT
    While we strive to ensure accurate Swedish word order and translations, we cannot guarantee the accuracy of all content. Users are responsible for verifying information and should consult additional resources for comprehensive learning.
    
    3. LIMITATION OF LIABILITY
    To the fullest extent permitted by law, SWWorder shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of data or use, arising out of or in connection with the use of the App.
    
    4. USER RESPONSIBILITY
    Users are solely responsible for:
    - Verifying word order and translations
    - Using the App as a supplementary learning tool
    - Maintaining the security of their device
    
    5. THIRD-PARTY SERVICES
    The App may integrate system services. These are subject to their own terms of use and privacy policies.
    
    6. CHANGES TO THE APP
    We reserve the right to modify, suspend, or discontinue the App at any time without prior notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance.
    
    7. NO PROFESSIONAL ADVICE
    The App is for educational and learning purposes only. It does not constitute professional language instruction or certification. Users should consult with qualified language instructors for formal education.
    
    8. ACCEPTANCE
    By using SWWorder, you acknowledge that you have read, understood, and agree to this Disclaimer.
    """
}

// MARK: - Help & Support View (Worder)
struct WorderHelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showForm = false
    @State private var showError = false
    @State private var alertType: AlertType = .none
    
    enum AlertType {
        case none
        case messageSent
    }
    
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
                                .fontWeight(.semibold)
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
                                
                                Text("Whether you have questions about")
                                    .font(.body)
                                
                                Text("SWWorder, feedback, or just want to say hi,")
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
                            Text("Help & Support")
                                .font(.headline)
                                .fontWeight(.semibold)
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
                case .none:
                    return Alert(title: Text(""), message: Text(""), dismissButton: .default(Text("")))
                }
            }
        }
    }
}

// MARK: - About View (Worder)
struct WorderAboutView: View {
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
                    VStack(alignment: .center, spacing: 8) {
                        Text(appVersion)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About SWWorder")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("SWWorder is a Swedish word order practice app designed to help you master Swedish sentence structure with ease. Practice word order with sentence blocks (V2 rule, negation, questions, auxiliaries), complete practice sessions, track your progress through session summaries and history, and use grammar tips and translations. Set daily reminders to keep your practice consistent and build your Swedish word order skills systematically.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
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
                        .fontWeight(.semibold)
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

#Preview {
    WorderSettingsView()
}
