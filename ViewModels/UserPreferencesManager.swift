import Foundation
import SwiftUI
import Combine

class UserPreferencesManager: ObservableObject {
    @Published var userPreferences: UserPreferences
    @Published var firebaseFavoriteStatus: [String: Bool] = [:] // Cache for Firebase favorite status
    
    private var firebaseManager: FirebaseManager?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load from UserDefaults (for offline cache)
        if let data = UserDefaults.standard.data(forKey: "UserPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        } else {
            self.userPreferences = UserPreferences()
            savePreferences() // Save the newly created preferences with device ID
        }
        
        print("📱 Device ID: \(userPreferences.deviceId)")
    }
    
    func setFirebaseManager(_ firebaseManager: FirebaseManager) {
        self.firebaseManager = firebaseManager
        loadFirebaseFavorites()
    }
    
    // MARK: - Favorites Management (Firebase + Local Cache)
    
    func isFavorite(barId: String) -> Bool {
        // First check Firebase cache, then fall back to local cache
        return firebaseFavoriteStatus[barId] ?? userPreferences.favoriteBarIDs.contains(barId)
    }
    
    func toggleFavorite(barId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let firebaseManager = firebaseManager else {
            // Fallback to local-only mode if Firebase isn't available
            toggleLocalFavorite(barId: barId)
            completion(isFavorite(barId: barId))
            return
        }
        
        print("🔄 Toggling favorite for bar: \(barId)")
        
        firebaseManager.toggleFavorite(barId: barId, deviceId: userPreferences.deviceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isNowFavorited):
                    // Update local cache
                    self?.firebaseFavoriteStatus[barId] = isNowFavorited
                    
                    if isNowFavorited {
                        self?.userPreferences.favoriteBarIDs.insert(barId)
                        print("❤️ Added \(barId) to favorites (Firebase + Local)")
                    } else {
                        self?.userPreferences.favoriteBarIDs.remove(barId)
                        print("💔 Removed \(barId) from favorites (Firebase + Local)")
                    }
                    
                    self?.savePreferences()
                    completion(isNowFavorited)
                    
                case .failure(let error):
                    print("❌ Error toggling favorite: \(error.localizedDescription)")
                    // Fallback to local toggle on error
                    self?.toggleLocalFavorite(barId: barId)
                    completion(self?.isFavorite(barId: barId) ?? false)
                }
            }
        }
    }
    
    private func toggleLocalFavorite(barId: String) {
        if userPreferences.favoriteBarIDs.contains(barId) {
            userPreferences.favoriteBarIDs.remove(barId)
            print("💔 Removed \(barId) from local favorites")
        } else {
            userPreferences.favoriteBarIDs.insert(barId)
            print("❤️ Added \(barId) to local favorites")
        }
        savePreferences()
    }
    
    func getFavoriteBarIds() -> Set<String> {
        return userPreferences.favoriteBarIDs
    }
    
    // MARK: - Firebase Integration
    
    private func loadFirebaseFavorites() {
        guard let firebaseManager = firebaseManager else { return }
        
        // Load favorite status for all bars that we have locally
        for barId in userPreferences.favoriteBarIDs {
            firebaseManager.checkIfUserFavoritedBar(barId: barId, deviceId: userPreferences.deviceId) { [weak self] isFavorited in
                DispatchQueue.main.async {
                    self?.firebaseFavoriteStatus[barId] = isFavorited
                    
                    // If Firebase says it's not favorited but we have it locally, sync the state
                    if !isFavorited && self?.userPreferences.favoriteBarIDs.contains(barId) == true {
                        self?.userPreferences.favoriteBarIDs.remove(barId)
                        self?.savePreferences()
                        print("🔄 Synced: Removed \(barId) from local cache (not in Firebase)")
                    }
                }
            }
        }
    }
    
    func syncFavoriteStatus(for barId: String) {
        guard let firebaseManager = firebaseManager else { return }
        
        firebaseManager.checkIfUserFavoritedBar(barId: barId, deviceId: userPreferences.deviceId) { [weak self] isFavorited in
            DispatchQueue.main.async {
                self?.firebaseFavoriteStatus[barId] = isFavorited
                
                // Update local cache to match Firebase
                if isFavorited {
                    self?.userPreferences.favoriteBarIDs.insert(barId)
                } else {
                    self?.userPreferences.favoriteBarIDs.remove(barId)
                }
                
                self?.savePreferences()
            }
        }
    }
    
    // Sync all favorite statuses (useful for app launch)
    func syncAllFavoriteStatuses(for barIds: [String]) {
        guard let firebaseManager = firebaseManager else { return }
        
        for barId in barIds {
            firebaseManager.checkIfUserFavoritedBar(barId: barId, deviceId: userPreferences.deviceId) { [weak self] isFavorited in
                DispatchQueue.main.async {
                    self?.firebaseFavoriteStatus[barId] = isFavorited
                }
            }
        }
    }
    
    // MARK: - Local Storage
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(data, forKey: "UserPreferences")
        }
    }
    
    // MARK: - Debug/Testing Methods
    
    func clearAllFavorites() {
        userPreferences.favoriteBarIDs.removeAll()
        firebaseFavoriteStatus.removeAll()
        savePreferences()
        print("🧹 Cleared all local favorites")
    }
    
    func debugPrintStatus() {
        print("📊 Favorites Debug Info:")
        print("   Device ID: \(userPreferences.deviceId)")
        print("   Local favorites: \(userPreferences.favoriteBarIDs)")
        print("   Firebase cache: \(firebaseFavoriteStatus)")
    }
}
