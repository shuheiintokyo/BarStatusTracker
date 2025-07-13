import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    // 🎵 SIMPLIFIED SOUND SETTINGS - Only Opening Soon and Closing Soon
    @Published var enableSoundsForOpeningSoon = true
    @Published var enableSoundsForClosingSoon = true
    
    init() {
        checkNotificationPermissions()
        setupBarStatusListener()
        loadSoundPreferences()
    }
    
    // MARK: - Simplified Sound Preferences
    
    private func loadSoundPreferences() {
        enableSoundsForOpeningSoon = UserDefaults.standard.bool(forKey: "enableSoundsForOpeningSoon")
        enableSoundsForClosingSoon = UserDefaults.standard.bool(forKey: "enableSoundsForClosingSoon")
        
        // Set defaults on first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            enableSoundsForOpeningSoon = true
            enableSoundsForClosingSoon = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            saveSoundPreferences()
        }
    }
    
    private func saveSoundPreferences() {
        UserDefaults.standard.set(enableSoundsForOpeningSoon, forKey: "enableSoundsForOpeningSoon")
        UserDefaults.standard.set(enableSoundsForClosingSoon, forKey: "enableSoundsForClosingSoon")
    }
    
    func toggleSoundForOpen() {
        enableSoundsForOpeningSoon.toggle()
        saveSoundPreferences()
    }
    
    func toggleSoundForClosing() {
        enableSoundsForClosingSoon.toggle()
        saveSoundPreferences()
    }
    
    // Keep these for backwards compatibility with existing code
    var enableSoundsForOpen: Bool { enableSoundsForOpeningSoon }
    var enableSoundsForClosing: Bool { enableSoundsForClosingSoon }
    var silentForClosed: Bool { true } // Always silent for closed
    
    // 🎵 SIMPLIFIED: Only handle Opening Soon and Closing Soon
    private func shouldPlaySound(for status: BarStatus) -> Bool {
        switch status {
        case .openingSoon:
            return enableSoundsForOpeningSoon
        case .closingSoon:
            return enableSoundsForClosingSoon
        case .open, .closed:
            return false // No notifications for immediate states
        }
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
    
    // MARK: - Bar Status Listener
    
    private func setupBarStatusListener() {
        NotificationCenter.default.addObserver(
            forName: .barStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let barName = userInfo["barName"] as? String,
                  let newStatus = userInfo["newStatus"] as? BarStatus,
                  let barId = userInfo["barId"] as? String else { return }
            
            // Only send notifications for Opening Soon and Closing Soon
            guard newStatus == .openingSoon || newStatus == .closingSoon else {
                print("🔕 Skipping notification for \(newStatus.displayName) - only notifying for Opening Soon/Closing Soon")
                return
            }
            
            let userPreferencesManager = UserPreferencesManager()
            if userPreferencesManager.isFavorite(barId: barId) {
                self?.scheduleBarStatusNotification(barName: barName, newStatus: newStatus)
                print("🔔 Sending \(newStatus.displayName) notification for favorited bar: \(barName)")
            } else {
                print("🔕 Skipping notification for non-favorited bar: \(barName)")
            }
        }
    }
    
    // MARK: - Send Notifications (SIMPLIFIED)
    
    func scheduleBarStatusNotification(barName: String, newStatus: BarStatus) {
        guard isAuthorized else {
            print("❌ Notifications not authorized - skipping notification for \(barName)")
            return
        }
        
        // Only send notifications for Opening Soon and Closing Soon
        guard newStatus == .openingSoon || newStatus == .closingSoon else {
            print("🔕 Skipping notification for \(newStatus.displayName) - only sending for Opening Soon/Closing Soon")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🍺 \(barName)"
        content.body = getNotificationMessage(for: newStatus)
        
        // 🎵 Sound handling for simplified statuses
        if shouldPlaySound(for: newStatus) {
            content.sound = .default
        }
        // If shouldPlaySound returns false, we don't set content.sound (defaults to silent)
        
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
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                let soundStatus = self.shouldPlaySound(for: newStatus) ? "With Sound" : "Silent"
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
            return "Now open! Come on by 🎉" // Won't be used but kept for safety
        case .closed:
            return "Now closed. See you next time! 👋" // Won't be used but kept for safety
        }
    }
    
    // MARK: - Settings Redirect
    
    func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// Extension for notification names
extension Notification.Name {
    static let barStatusChanged = Notification.Name("barStatusChanged")
}
