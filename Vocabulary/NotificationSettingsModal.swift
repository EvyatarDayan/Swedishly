import SwiftUI

struct NotificationSettingsModal: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var localNotificationTime: Date
    
    init() {
        // Initialize with current notification time
        let manager = NotificationManager.shared
        _localNotificationTime = State(initialValue: manager.notificationTime)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Toggle section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notifications")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appRed)
                    
                    Toggle("Enable Daily Reminders", isOn: Binding(
                        get: { notificationManager.notificationsEnabled },
                        set: { newValue in
                            notificationManager.toggleNotifications(newValue)
                        }
                    ))
                    .font(.system(size: 17))
                    .tint(.appRed)
                    
                    if notificationManager.notificationsEnabled {
                        Text("You'll receive a daily reminder to practice your Swedish vocabulary.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Time picker section
                if notificationManager.notificationsEnabled {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Reminder Time")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.appRed)
                        
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { localNotificationTime },
                                set: { newTime in
                                    localNotificationTime = newTime
                                    notificationManager.updateNotificationTime(newTime)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        
                        Text("Choose when you'd like to receive your daily practice reminder.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Notification Settings")
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
