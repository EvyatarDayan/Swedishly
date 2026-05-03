import Foundation
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notificationsEnabled: Bool = false
    @Published var notificationTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20 // Default to 8 PM
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    
    private let notificationsEnabledKey = "notificationsEnabled"
    private let notificationTimeKey = "notificationTime"
    
    private init() {
        loadSettings()
        checkNotificationPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationsEnabled = true
                    self.saveSettings()
                    self.scheduleNotifications()
                } else {
                    self.notificationsEnabled = false
                    self.saveSettings()
                }
            }
        }
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
                if self.notificationsEnabled {
                    self.scheduleNotifications()
                }
            }
        }
    }
    
    func toggleNotifications(_ enabled: Bool) {
        if enabled {
            // Check current permission status
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .authorized {
                        self.notificationsEnabled = true
                        self.saveSettings()
                        self.scheduleNotifications()
                    } else {
                        // Request permission
                        self.requestPermission()
                    }
                }
            }
        } else {
            notificationsEnabled = false
            saveSettings()
            cancelNotifications()
        }
    }
    
    func updateNotificationTime(_ time: Date) {
        notificationTime = time
        saveSettings()
        if notificationsEnabled {
            scheduleNotifications()
        }
    }
    
    private func scheduleNotifications() {
        // Cancel existing notifications
        cancelNotifications()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Practice!"
        content.body = "Don't forget to practice your Swedish vocabulary today. Lycka till! 🎯"
        content.sound = .default
        content.badge = 1
        
        // Extract hour and minute from notification time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        
        // Create daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let identifier = "dailyVocabularyReminder"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("✅ Notification scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: notificationsEnabledKey)
        UserDefaults.standard.set(notificationTime, forKey: notificationTimeKey)
    }
    
    private func loadSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        if let savedTime = UserDefaults.standard.object(forKey: notificationTimeKey) as? Date {
            notificationTime = savedTime
        }
    }
}
