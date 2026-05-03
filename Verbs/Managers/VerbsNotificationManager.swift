//
//  VerbsNotificationManager.swift
//  SWVerbs (renamed from NotificationManager to avoid conflict with Vocabulary)
//

import Foundation
import UserNotifications
import Combine

class VerbsNotificationManager: ObservableObject {
    static let shared = VerbsNotificationManager()

    @Published var hasPermission = false
    @Published var isScheduled = false
    @Published var scheduledTime: Date?
    @Published var nextNotificationDate: Date?

    private let notificationCenter = UNUserNotificationCenter.current()
    private let scheduledTimeKey = "scheduledNotificationTime"
    private let isScheduledKey = "isNotificationScheduled"

    private init() {
        checkPermissionStatus()
        loadScheduledState()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                self?.checkPermissionStatus()
                completion(granted)
            }
        }
    }

    func checkPermissionStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleDailyReminder(at time: Date) {
        guard hasPermission else {
            requestAuthorization { [weak self] granted in
                if granted { self?.scheduleDailyReminder(at: time) }
            }
            return
        }
        cancelAllNotifications()
        let content = UNMutableNotificationContent()
        content.title = "Time to Learn Swedish!"
        content.body = "Don't forget to practice your Swedish verbs today! 📚"
        content.sound = .default
        content.badge = 1
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyLearningReminder", content: content, trigger: trigger)
        notificationCenter.add(request) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.isScheduled = true
                    self?.scheduledTime = time
                    self?.saveScheduledState()
                    self?.updateNextNotificationDate()
                }
            }
        }
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        DispatchQueue.main.async {
            self.isScheduled = false
            self.scheduledTime = nil
            self.nextNotificationDate = nil
            self.saveScheduledState()
        }
    }

    private func updateNextNotificationDate() {
        guard let scheduledTime = scheduledTime else { return }
        let calendar = Calendar.current
        let now = Date()
        let scheduledComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        var nextDate = calendar.date(bySettingHour: scheduledComponents.hour ?? 0, minute: scheduledComponents.minute ?? 0, second: 0, of: now) ?? now
        if nextDate <= now {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }
        nextNotificationDate = nextDate
    }

    private func saveScheduledState() {
        UserDefaults.standard.set(isScheduled, forKey: isScheduledKey)
        if let scheduledTime = scheduledTime {
            UserDefaults.standard.set(scheduledTime, forKey: scheduledTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: scheduledTimeKey)
        }
    }

    private func loadScheduledState() {
        isScheduled = UserDefaults.standard.bool(forKey: isScheduledKey)
        if let savedTime = UserDefaults.standard.object(forKey: scheduledTimeKey) as? Date {
            scheduledTime = savedTime
            updateNextNotificationDate()
        }
        if isScheduled {
            notificationCenter.getPendingNotificationRequests { [weak self] requests in
                DispatchQueue.main.async {
                    if requests.isEmpty {
                        self?.isScheduled = false
                        self?.scheduledTime = nil
                    }
                }
            }
        }
    }
}
