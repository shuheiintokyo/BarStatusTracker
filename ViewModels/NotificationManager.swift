import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    init() {
        checkNotificationPermissions()
        setupBarStatusListener()  // 🎯 ADD THIS LINE
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("❌ Notification permissions denied")
                }
            }
        }
    }
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // 🎯 ADD THIS ENTIRE SECTION - Bar Status Listener
    // MARK: - Bar Status Listener
    
    private func setupBarStatusListener() {
        // Listen for bar status changes
        NotificationCenter.default.addObserver(
            forName: .barStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let barName = userInfo["barName"] as? String,
                  let newStatus = userInfo["newStatus"] as? BarStatus,
                  let barId = userInfo["barId"] as? String else { return }
            
            // Check if user has favorited this bar
            let userPreferencesManager = UserPreferencesManager()
            if userPreferencesManager.isFavorite(barId: barId) {
                self?.scheduleBarStatusNotification(barName: barName, newStatus: newStatus)
                print("🔔 Sending notification for favorited bar: \(barName)")
            } else {
                print("🔕 Skipping notification for non-favorited bar: \(barName)")
            }
        }
    }
    
    // MARK: - Send Notifications
    
    func scheduleBarStatusNotification(barName: String, newStatus: BarStatus) {
        guard isAuthorized else {
            print("❌ Notifications not authorized - skipping notification for \(barName)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🍺 \(barName)"  // 🎯 UPDATED EMOJI
        content.body = getNotificationMessage(for: newStatus)
        content.sound = .default
        
        // 🎯 ADD ACTION BUTTONS
        let viewAction = UNNotificationAction(
            identifier: "VIEW_BAR",
            title: "View Bar",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "BAR_STATUS",
            actions: [viewAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "BAR_STATUS"
        
        // Create identifier
        let identifier = "bar-status-\(barName)-\(Date().timeIntervalSince1970)"
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("📱 ✅ Scheduled notification for \(barName): \(newStatus.displayName)")
            }
        }
    }
    
    private func getNotificationMessage(for status: BarStatus) -> String {
        switch status {
        case .openingSoon:
            return "Opening soon! Get ready to head over 🍺"
        case .open:
            return "Now open! Come on by 🎉"
        case .closingSoon:
            return "Closing soon - last call! ⏰"
        case .closed:
            return "Now closed. See you next time! 👋"
        }
    }
    
    // MARK: - Settings Redirect
    
    func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// 🎯 ADD THIS EXTENSION AT THE BOTTOM
// Extension for notification names
extension Notification.Name {
    static let barStatusChanged = Notification.Name("barStatusChanged")
}
