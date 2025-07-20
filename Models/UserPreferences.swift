import Foundation

// Simplified user preferences without favorites
struct UserPreferences: Codable {
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
