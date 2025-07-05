import Foundation

// Simple user preferences for favorites
struct UserPreferences: Codable {
    var favoriteBarIDs: Set<String> = []
    var deviceId: String
    
    // Initialize with automatic device ID
    init() {
        self.deviceId = UUID().uuidString
    }
    
    // Initialize with specific device ID (for loading from storage)
    init(deviceId: String) {
        self.deviceId = deviceId
    }
}

// Notification settings (simplified)
struct NotificationSettings: Codable {
    var statusChangeNotifications: Bool = true
    var openingNotifications: Bool = true
    var closingNotifications: Bool = true
    
    init() {}
}
