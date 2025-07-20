import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    // Sound settings
    @Published var enableSoundsForOpeningSoon = true
    @Published var enableSoundsForClosingSoon = true
    
    // Simple notification control
    @Published var enableNotifications = true
    
    init() {
        checkNotificationPermissions()
        setupBarStatusListener()
        loadSettings()
        
        print("📱 Notification system initialized")
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        enableSoundsForOpeningSoon = UserDefaults.standard.bool(forKey: "enableSoundsForOpeningSoon")
        enableSoundsForClosingSoon = UserDefaults.standard.bool(forKey: "enableSoundsForClosingSoon")
        enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
        
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            enableSoundsForOpeningSoon = true
            enableSoundsForClosingSoon = true
            enableNotifications = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            saveSettings()
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(enableSoundsForOpeningSoon, forKey: "enableSoundsForOpeningSoon")
        UserDefaults.standard.set(enableSoundsForClosingSoon, forKey: "enableSoundsForClosingSoon")
        UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
    }
    
    func toggleSoundForOpen() {
        enableSoundsForOpeningSoon.toggle()
        saveSettings()
        print("🔊 Opening Soon sound: \(enableSoundsForOpeningSoon)")
    }
    
    func toggleSoundForClosing() {
        enableSoundsForClosingSoon.toggle()
        saveSettings()
        print("🔊 Closing Soon sound: \(enableSoundsForClosingSoon)")
    }
    
    func toggleNotifications() {
        enableNotifications.toggle()
        saveSettings()
        print("🔔 Notifications enabled: \(enableNotifications)")
    }
    
    // Keep these for backwards compatibility
    var enableSoundsForOpen: Bool { enableSoundsForOpeningSoon }
    var enableSoundsForClosing: Bool { enableSoundsForClosingSoon }
    var silentForClosed: Bool { true }
    
    private func shouldPlaySound(for status: BarStatus) -> Bool {
        switch status {
        case .openingSoon:
            return enableSoundsForOpeningSoon
        case .closingSoon:
            return enableSoundsForClosingSoon
        case .open, .closed:
            return false
        }
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    print("✅ Notification permissions granted")
                    // Send welcome test notification
                    self?.sendWelcomeNotification()
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
                print("📱 Notification auth status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    private func sendWelcomeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🍺 Welcome to Bar Status Tracker!"
        content.body = "You'll now receive notifications when bars are opening or closing soon."
        content.sound = .default
        
        let identifier = "welcome-\(Date().timeIntervalSince1970)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send welcome notification: \(error)")
            } else {
                print("📱 Welcome notification scheduled")
            }
        }
    }
    
    // MARK: - Simplified Bar Status Listener
    
    private func setupBarStatusListener() {
        NotificationCenter.default.addObserver(
            forName: .barStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // Check if notifications are enabled
            guard self.enableNotifications else {
                print("🔕 Notifications disabled by user")
                return
            }
            
            guard let userInfo = notification.userInfo,
                  let barName = userInfo["barName"] as? String,
                  let newStatus = userInfo["newStatus"] as? BarStatus else {
                print("❌ Invalid notification userInfo")
                return
            }
            
            let isScheduleBased = userInfo["isScheduleBased"] as? Bool ?? false
            
            print("📢 Received status change: \(barName) → \(newStatus.displayName) (schedule: \(isScheduleBased))")
            
            // Only send notifications for Opening Soon and Closing Soon
            guard newStatus == .openingSoon || newStatus == .closingSoon else {
                print("🔕 Skipping notification for \(newStatus.displayName)")
                return
            }
            
            // Send notification to everyone (simplified - no favorites)
            self.scheduleBarStatusNotification(barName: barName, newStatus: newStatus)
            print("🔔 Scheduling notification for bar: \(barName)")
        }
    }
    
    // MARK: - Send Notifications
    
    func scheduleBarStatusNotification(barName: String, newStatus: BarStatus) {
        guard isAuthorized else {
            print("❌ Notifications not authorized - skipping notification for \(barName)")
            return
        }
        
        guard enableNotifications else {
            print("🔕 Notifications disabled by user - skipping notification for \(barName)")
            return
        }
        
        guard newStatus == .openingSoon || newStatus == .closingSoon else {
            print("🔕 Only sending notifications for Opening Soon/Closing Soon")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🍺 \(barName)"
        content.body = getNotificationMessage(for: newStatus)
        
        // Sound handling
        if shouldPlaySound(for: newStatus) {
            content.sound = .default
        }
        
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
        
        let identifier = "bar-status-\(barName)-\(Date().timeIntervalSince1970)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                let soundStatus = self?.shouldPlaySound(for: newStatus) == true ? "With Sound" : "Silent"
                print("📱 🎵 Scheduled \(newStatus.displayName) notification for \(barName) [\(soundStatus)]")
            }
        }
    }
    
    private func getNotificationMessage(for status: BarStatus) -> String {
        switch status {
        case .openingSoon:
            return "Opening soon! Get ready to head over 🍺"
        case .closingSoon:
            return "Closing soon - last call! ⏰"
        case .open:
            return "Now open! Come on by 🎉"
        case .closed:
            return "Now closed. See you next time! 👋"
        }
    }
    
    // MARK: - Testing Methods
    
    func sendTestNotification() {
        scheduleBarStatusNotification(barName: "Test Bar", newStatus: .openingSoon)
    }
    
    // MARK: - Settings
    
    func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Debug Info
    
    func getDebugInfo() -> String {
        return """
        Authorized: \(isAuthorized)
        Notifications Enabled: \(enableNotifications)
        Opening Soon Sound: \(enableSoundsForOpeningSoon)
        Closing Soon Sound: \(enableSoundsForClosingSoon)
        """
    }
}

// Extension for notification names
extension Notification.Name {
    static let barStatusChanged = Notification.Name("barStatusChanged")
}
