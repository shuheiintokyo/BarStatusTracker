import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    // 🎵 SIMPLE SOUND SETTINGS
    @Published var enableSoundsForOpen = true
    @Published var enableSoundsForClosing = true
    @Published var silentForClosed = true
    
    init() {
        checkNotificationPermissions()
        setupBarStatusListener()
        loadSoundPreferences()
    }
    
    // MARK: - Simple Sound Preferences
    
    private func loadSoundPreferences() {
        enableSoundsForOpen = UserDefaults.standard.bool(forKey: "enableSoundsForOpen")
        enableSoundsForClosing = UserDefaults.standard.bool(forKey: "enableSoundsForClosing")
        silentForClosed = UserDefaults.standard.bool(forKey: "silentForClosed")
        
        // Set defaults on first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            enableSoundsForOpen = true
            enableSoundsForClosing = true
            silentForClosed = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            saveSoundPreferences()
        }
    }
    
    private func saveSoundPreferences() {
        UserDefaults.standard.set(enableSoundsForOpen, forKey: "enableSoundsForOpen")
        UserDefaults.standard.set(enableSoundsForClosing, forKey: "enableSoundsForClosing")
        UserDefaults.standard.set(silentForClosed, forKey: "silentForClosed")
    }
    
    func toggleSoundForOpen() {
        enableSoundsForOpen.toggle()
        saveSoundPreferences()
    }
    
    func toggleSoundForClosing() {
        enableSoundsForClosing.toggle()
        saveSoundPreferences()
    }
    
    func toggleSilentForClosed() {
        silentForClosed.toggle()
        saveSoundPreferences()
    }
    
    // 🎵 FIXED: Proper way to handle silent notifications
    private func shouldPlaySound(for status: BarStatus) -> Bool {
        switch status {
        case .openingSoon:
            return enableSoundsForOpen
        case .open:
            return enableSoundsForOpen
        case .closingSoon:
            return enableSoundsForClosing
        case .closed:
            return !silentForClosed
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
            
            let userPreferencesManager = UserPreferencesManager()
            if userPreferencesManager.isFavorite(barId: barId) {
                self?.scheduleBarStatusNotification(barName: barName, newStatus: newStatus)
                print("🔔 Sending notification for favorited bar: \(barName)")
            } else {
                print("🔕 Skipping notification for non-favorited bar: \(barName)")
            }
        }
    }
    
    // MARK: - Send Notifications (FIXED)
    
    func scheduleBarStatusNotification(barName: String, newStatus: BarStatus) {
        guard isAuthorized else {
            print("❌ Notifications not authorized - skipping notification for \(barName)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🍺 \(barName)"
        content.body = getNotificationMessage(for: newStatus)
        
        // 🎵 FIXED: Proper sound handling
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
                print("📱 🎵 Scheduled notification for \(barName): \(newStatus.displayName) [\(soundStatus)]")
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

// Extension for notification names
extension Notification.Name {
    static let barStatusChanged = Notification.Name("barStatusChanged")
}
