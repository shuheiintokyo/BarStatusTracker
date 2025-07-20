import Foundation
import SwiftUI
import Combine

class UserPreferencesManager: ObservableObject {
    @Published var userPreferences: UserPreferences
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load from UserDefaults (for basic app preferences)
        if let data = UserDefaults.standard.data(forKey: "UserPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        } else {
            self.userPreferences = UserPreferences()
            savePreferences()
        }
        
        print("📱 Device ID: \(userPreferences.deviceId)")
    }
    
    // MARK: - Local Storage
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(data, forKey: "UserPreferences")
        }
        print("💾 Saved basic preferences")
    }
    
    // MARK: - Debug Methods
    
    func debugPrintStatus() {
        print("📊 User Preferences Debug Info:")
        print("   Device ID: \(userPreferences.deviceId)")
    }
}
