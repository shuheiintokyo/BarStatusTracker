import Foundation
import SwiftUI
import Combine

class UserPreferencesManager: ObservableObject {
    @Published var userPreferences: UserPreferences
    @Published var firebaseFavoriteStatus: [String: Bool] = [:] // Cache for Firebase favorite status
    @Published var isLoading = false
    
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
        print("📱 Local favorites loaded: \(userPreferences.favoriteBarIDs)")
    }
    
    func setFirebaseManager(_ firebaseManager: FirebaseManager) {
        self.firebaseManager = firebaseManager
        
        // Listen to Firebase favorite counts to detect changes
        firebaseManager.$favoriteCounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // When favorite counts change, refresh our local cache
                self?.refreshAllFavoriteStatuses()
            }
            .store(in: &cancellables)
        
        // Initial load
        loadFirebaseFavorites()
    }
    
    // MARK: - Favorites Management (Fixed with better syncing)
    
    func isFavorite(barId: String) -> Bool {
        // Check Firebase cache first (more authoritative), then fall back to local
        if let firebaseFavorite = firebaseFavoriteStatus[barId] {
            return firebaseFavorite
        }
        
        // Fallback to local cache
        let localFavorite = userPreferences.favoriteBarIDs.contains(barId)
        
        // If we have a local favorite but no Firebase data, sync it
        if localFavorite && firebaseFavoriteStatus[barId] == nil {
            syncFavoriteStatus(for: barId)
        }
        
        return localFavorite
    }
    
    func toggleFavorite(barId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let firebaseManager = firebaseManager else {
            // Fallback to local-only mode if Firebase isn't available
            toggleLocalFavorite(barId: barId)
            completion(isFavorite(barId: barId))
            return
        }
        
        print("🔄 Toggling favorite for bar: \(barId)")
        isLoading = true
        
        firebaseManager.toggleFavorite(barId: barId, deviceId: userPreferences.deviceId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let isNowFavorited):
                    // Update both caches immediately
                    self?.firebaseFavoriteStatus[barId] = isNowFavorited
                    
                    if isNowFavorited {
                        self?.userPreferences.favoriteBarIDs.insert(barId)
                        print("❤️ Added \(barId) to favorites (Firebase + Local)")
                    } else {
                        self?.userPreferences.favoriteBarIDs.remove(barId)
                        print("💔 Removed \(barId) from favorites (Firebase + Local)")
                    }
                    
                    self?.savePreferences()
                    self?.objectWillChange.send()
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
            firebaseFavoriteStatus[barId] = false
            print("💔 Removed \(barId) from local favorites")
        } else {
            userPreferences.favoriteBarIDs.insert(barId)
            firebaseFavoriteStatus[barId] = true
            print("❤️ Added \(barId) to local favorites")
        }
        savePreferences()
        objectWillChange.send()
    }
    
    func getFavoriteBarIds() -> Set<String> {
        // Return combined set from Firebase cache and local cache
        var allFavorites = userPreferences.favoriteBarIDs
        
        // Add any Firebase favorites that might not be in local cache
        for (barId, isFavorited) in firebaseFavoriteStatus {
            if isFavorited {
                allFavorites.insert(barId)
            } else {
                allFavorites.remove(barId)
            }
        }
        
        // Update local cache to match the combined result
        if allFavorites != userPreferences.favoriteBarIDs {
            userPreferences.favoriteBarIDs = allFavorites
            savePreferences()
        }
        
        print("📊 Combined favorites: \(allFavorites)")
        return allFavorites
    }
    
    // MARK: - Firebase Integration (Enhanced)
    
    private func loadFirebaseFavorites() {
        guard let firebaseManager = firebaseManager else { return }
        
        print("🔄 Loading Firebase favorites for all bars...")
        
        // Load favorite status for all bars that we have locally
        for barId in userPreferences.favoriteBarIDs {
            firebaseManager.checkIfUserFavoritedBar(barId: barId, deviceId: userPreferences.deviceId) { [weak self] isFavorited in
                DispatchQueue.main.async {
                    self?.firebaseFavoriteStatus[barId] = isFavorited
                    
                    // If Firebase says it's not favorited but we have it locally, sync the state
                    if !isFavorited && self?.userPreferences.favoriteBarIDs.contains(barId) == true {
                        print("🔄 Synced: Removed \(barId) from local cache (not in Firebase)")
                        self?.userPreferences.favoriteBarIDs.remove(barId)
                        self?.savePreferences()
                        self?.objectWillChange.send()
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
                self?.objectWillChange.send()
                print("🔄 Synced favorite status for \(barId): \(isFavorited)")
            }
        }
    }
    
    // Sync all favorite statuses (useful for app launch)
    func syncAllFavoriteStatuses(for barIds: [String]) {
        guard let firebaseManager = firebaseManager else { return }
        
        print("🔄 Syncing all favorite statuses for \(barIds.count) bars...")
        
        for barId in barIds {
            firebaseManager.checkIfUserFavoritedBar(barId: barId, deviceId: userPreferences.deviceId) { [weak self] isFavorited in
                DispatchQueue.main.async {
                    self?.firebaseFavoriteStatus[barId] = isFavorited
                }
            }
        }
    }
    
    // Refresh favorite statuses for bars we think we've favorited
    private func refreshAllFavoriteStatuses() {
        guard let firebaseManager = firebaseManager else { return }
        
        let allPotentialFavorites = Array(userPreferences.favoriteBarIDs.union(Set(firebaseFavoriteStatus.keys)))
        
        for barId in allPotentialFavorites {
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
        
        // Trigger UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Local Storage
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(data, forKey: "UserPreferences")
        }
        print("💾 Saved preferences with \(userPreferences.favoriteBarIDs.count) favorites")
    }
    
    // MARK: - Debug/Testing Methods
    
    func clearAllFavorites() {
        userPreferences.favoriteBarIDs.removeAll()
        firebaseFavoriteStatus.removeAll()
        savePreferences()
        print("🧹 Cleared all local favorites")
        objectWillChange.send()
    }
    
    func debugPrintStatus() {
        print("📊 Favorites Debug Info:")
        print("   Device ID: \(userPreferences.deviceId)")
        print("   Local favorites: \(userPreferences.favoriteBarIDs)")
        print("   Firebase cache: \(firebaseFavoriteStatus)")
        
        let combined = getFavoriteBarIds()
        print("   Combined result: \(combined)")
    }
    
    // Force refresh favorites from Firebase
    func forceRefreshFavorites() {
        guard let firebaseManager = firebaseManager else { return }
        
        print("🔄 Force refreshing all favorites...")
        isLoading = true
        
        // Get all bar IDs from the current bars list
        let allBarIds = Array(userPreferences.favoriteBarIDs)
        
        var completedChecks = 0
        let totalChecks = allBarIds.count
        
        for barId in allBarIds {
            firebaseManager.checkIfUserFavoritedBar(barId: barId, deviceId: userPreferences.deviceId) { [weak self] isFavorited in
                DispatchQueue.main.async {
                    self?.firebaseFavoriteStatus[barId] = isFavorited
                    
                    completedChecks += 1
                    if completedChecks >= totalChecks {
                        self?.isLoading = false
                        self?.objectWillChange.send()
                        print("✅ Completed force refresh of favorites")
                    }
                }
            }
        }
        
        // If no bars to check, stop loading immediately
        if totalChecks == 0 {
            isLoading = false
        }
    }
}
