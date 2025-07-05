import Foundation
import SwiftUI

class UserPreferencesManager: ObservableObject {
    @Published var userPreferences: UserPreferences
    
    init() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "UserPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        } else {
            self.userPreferences = UserPreferences()
        }
    }
    
    // MARK: - Favorites Management (Local Only)
    
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
    
    private func addFavorite(barId: String) {
        userPreferences.favoriteBarIDs.insert(barId)
        savePreferences()
        print("⭐ Added \(barId) to local favorites")
    }
    
    private func removeFavorite(barId: String) {
        userPreferences.favoriteBarIDs.remove(barId)
        savePreferences()
        print("💔 Removed \(barId) from local favorites")
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
}
