//
//  ScheduleView.swift
//  SWVerbs
//
//  Created by EVYATAR DAYAN on 2026-01-05.
//

import SwiftUI
import UserNotifications

struct ScheduleView: View {
    @StateObject private var notificationManager = VerbsNotificationManager.shared
    @State private var selectedTime = Date()
    @State private var isEnabled = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Daily Reminder")) {
                    Toggle("Enable Reminder", isOn: $isEnabled)
                        .onChange(of: isEnabled) { oldValue, newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                notificationManager.cancelAllNotifications()
                            }
                        }
                    
                    if isEnabled {
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .onChange(of: selectedTime) { oldValue, newValue in
                                if isEnabled {
                                    scheduleNotification()
                                }
                            }
                    }
                }
                
                if isEnabled {
                    Section(header: Text("Reminder Details")) {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(notificationManager.hasPermission ? "Active" : "Permission Required")
                                .foregroundColor(notificationManager.hasPermission ? .green : .orange)
                        }
                        
                        if let nextNotificationDate = notificationManager.nextNotificationDate {
                            HStack {
                                Text("Next Reminder")
                                Spacer()
                                Text(nextNotificationDate, style: .time)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SplitTitleView("Schedule", splitIndex: 4)
                }
            }
            .onAppear {
                isEnabled = notificationManager.isScheduled
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
                Button("Cancel", role: .cancel) {
                    isEnabled = false
                }
            } message: {
                Text("Please enable notifications in Settings to receive daily learning reminders.")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func requestNotificationPermission() {
        notificationManager.requestAuthorization { granted in
            if granted {
                scheduleNotification()
            } else {
                DispatchQueue.main.async {
                    showingPermissionAlert = true
                    isEnabled = false
                }
            }
        }
    }
    
    private func scheduleNotification() {
        notificationManager.scheduleDailyReminder(at: selectedTime)
    }
}

#Preview {
    ScheduleView()
}


