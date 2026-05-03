//
//  Managers.swift
//  Swedisher
//
//  Created by EVYATAR DAYAN on 2026-01-28.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Wrong Answers Manager (Adjectives)
class AdjectivesWrongAnswersManager: ObservableObject {
    static let shared = AdjectivesWrongAnswersManager()
    
    private init() {}
    
    func clearAllWrongAnswers() {
        // Clear wrong answers implementation
        UserDefaults.standard.removeObject(forKey: "wrongAnswers")
    }
    
    func addWrongAnswer(swedish: String, english: String) {
        // Add wrong answer implementation
    }
    
    func removeWrongAnswer(swedish: String, english: String) {
        // Remove wrong answer implementation
    }
    
    func recordCorrectAnswer(swedish: String, english: String) {
        // Record correct answer implementation
    }
}

// MARK: - Word State Manager (Adjectives)
class AdjectivesWordStateManager: ObservableObject {
    static let shared = AdjectivesWordStateManager()
    
    private init() {}
    
    func clearAllWordStates() {
        // Clear word states implementation
        UserDefaults.standard.removeObject(forKey: "wordStates")
    }
    
    func getWordState(swedish: String, english: String) -> AdjectivesWordState {
        // Get word state implementation
        return .new
    }
    
    func markWordAsSeen(swedish: String, english: String) {
        // Mark word as seen implementation
    }
    
    func recordAnswer(swedish: String, english: String, isCorrect: Bool) {
        // Record answer implementation
    }
    
    func getWordsByState(_ state: AdjectivesWordState) -> [AdjectivesWordStateData] {
        // Get words by state implementation
        return []
    }
    
    func getAllWordStates() -> [AdjectivesWordStateData] {
        // Get all word states implementation
        return []
    }
}

enum AdjectivesWordState {
    case new
    case weak
    case learning
    case review
    case mastered
}

struct AdjectivesWordStateData {
    let swedish: String
    let english: String
    let state: AdjectivesWordState
    let lastSeen: Date?
}

// MARK: - Test History Manager (Adjectives)
class AdjectivesTestHistoryManager: ObservableObject {
    static let shared = AdjectivesTestHistoryManager()
    
    private init() {}
    
    func clearAllHistory() {
        // Clear test history implementation
        UserDefaults.standard.removeObject(forKey: "adjectivesTestHistory")
    }
    
    var historyItems: [AdjectivesTestHistoryItem] {
        // Return test history items
        return []
    }
    
    func addHistoryItem(_ item: AdjectivesTestHistoryItem) {
        // Add history item implementation
    }
}

struct AdjectivesTestHistoryItem {
    let dateTaken: Date
    let questions: Int
    let correct: Int
    let wrong: Int
    let successPercentage: Int
}

// MARK: - Practice History Manager (Adjectives)
class AdjectivesPracticeHistoryManager: ObservableObject {
    static let shared = AdjectivesPracticeHistoryManager()
    
    private let historyKey = "adjectivesPracticeHistory"
    
    private init() {}
    
    func clearAllHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    var historyItems: [AdjectivesPracticeHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([AdjectivesPracticeHistoryItem].self, from: data)
        } catch {
            print("❌ Error loading adjectives practice history: \(error)")
            return []
        }
    }
    
    func addHistoryItem(_ item: AdjectivesPracticeHistoryItem) {
        var items = historyItems
        items.append(item)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("❌ Error saving adjectives practice history: \(error)")
        }
    }
    
    func deleteHistoryItem(_ item: AdjectivesPracticeHistoryItem) {
        var items = historyItems
        items.removeAll { $0.dateTaken == item.dateTaken && $0.questions == item.questions && $0.correct == item.correct && $0.wrong == item.wrong }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("❌ Error saving adjectives practice history after delete: \(error)")
        }
    }
}

enum AdjectivesPracticeType: String, Codable {
    case adjective
    case compare
    case antonym
}

struct AdjectivesPracticeQuestionSummary: Codable, Identifiable {
    let id: UUID
    let sentence: String
    let answer: String
    let englishAnswer: String
    let isCorrect: Bool
    
    init(sentence: String, answer: String, englishAnswer: String, isCorrect: Bool) {
        self.id = UUID()
        self.sentence = sentence
        self.answer = answer
        self.englishAnswer = englishAnswer
        self.isCorrect = isCorrect
    }
}

struct AdjectivesPracticeHistoryItem: Codable {
    let dateTaken: Date
    let questions: Int
    let correct: Int
    let wrong: Int
    let successPercentage: Int
    let practiceType: AdjectivesPracticeType?
    /// Optional per-question details (new items only).
    let questionsDetail: [AdjectivesPracticeQuestionSummary]?
    
    enum CodingKeys: String, CodingKey {
        case dateTaken, questions, correct, wrong, successPercentage, practiceType, questionsDetail
    }
    
    init(dateTaken: Date, questions: Int, correct: Int, wrong: Int, successPercentage: Int, practiceType: AdjectivesPracticeType? = nil, questionsDetail: [AdjectivesPracticeQuestionSummary]? = nil) {
        self.dateTaken = dateTaken
        self.questions = questions
        self.correct = correct
        self.wrong = wrong
        self.successPercentage = successPercentage
        self.practiceType = practiceType
        self.questionsDetail = questionsDetail
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateTaken = try container.decode(Date.self, forKey: .dateTaken)
        questions = try container.decode(Int.self, forKey: .questions)
        correct = try container.decode(Int.self, forKey: .correct)
        wrong = try container.decode(Int.self, forKey: .wrong)
        successPercentage = try container.decode(Int.self, forKey: .successPercentage)
        practiceType = try container.decodeIfPresent(AdjectivesPracticeType.self, forKey: .practiceType)
        questionsDetail = try container.decodeIfPresent([AdjectivesPracticeQuestionSummary].self, forKey: .questionsDetail)
    }
}

// MARK: - Notification Manager (Adjectives)
class AdjectivesNotificationManager: ObservableObject {
    static let shared = AdjectivesNotificationManager()
    
    private let notificationsEnabledKey = "adjectivesNotificationsEnabled"
    private let notificationTimeKey = "adjectivesNotificationTime"
    private let dailyReminderIdentifier = "adjectivesDailyPracticeReminder"
    
    @Published var notificationsEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: notificationsEnabledKey)
            if notificationsEnabled {
                scheduleDailyNotification()
            } else {
                cancelAllNotifications()
            }
        }
    }
    
    @Published var notificationTime: Date = Date() {
        didSet {
            UserDefaults.standard.set(notificationTime, forKey: notificationTimeKey)
            if notificationsEnabled {
                scheduleDailyNotification()
            }
        }
    }
    
    private init() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        if let savedTime = UserDefaults.standard.object(forKey: notificationTimeKey) as? Date {
            notificationTime = savedTime
        } else {
            // Default to 19:00 (7 PM)
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 19
            components.minute = 0
            notificationTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleDailyNotification() {
        cancelAllNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to practice!"
        content.body = "Don't forget to practice your Swedish today. Lycka till!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
    }
}
