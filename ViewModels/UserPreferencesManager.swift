import Foundation
import SwiftUI

class UserPreferencesManager: ObservableObject {
    @Published var userPreferences: UserPreferences
    @Published var hasNotificationPermission = false
    
    init() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "UserPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        } else {
            self.userPreferences = UserPreferences()
        }
    }
    
    // MARK: - Favorites Management
    
    func isFavorite(barId: String) -> Bool {
        return userPreferences.favoriteBarIDs.contains(barId)
    }
    
    func toggleFavorite(barId: String) {
        if userPreferences.favoriteBarIDs.contains(barId) {
            removeFavorite(barId: barId)
        } else {
            addFavorite(barId: barId)
        }
    }
    
    func addFavorite(barId: String) {
        userPreferences.favoriteBarIDs.insert(barId)
        savePreferences()
        print("⭐ Added \(barId) to favorites")
    }
    
    func removeFavorite(barId: String) {
        userPreferences.favoriteBarIDs.remove(barId)
        savePreferences()
        print("💔 Removed \(barId) from favorites")
    }
    
    func getFavoriteBarIds() -> Set<String> {
        return userPreferences.favoriteBarIDs
    }
    
    // MARK: - Local Storage
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(data, forKey: "UserPreferences")
        }
    }
    
    // Simple notification placeholder (no Firebase Messaging needed)
    func scheduleLocalNotification(title: String, body: String, barId: String) {
        print("📱 Notification: \(title) - \(body)")
        
        // Future enhancement: Add local notifications here
        // For now, just print to console for testing
    }
}
