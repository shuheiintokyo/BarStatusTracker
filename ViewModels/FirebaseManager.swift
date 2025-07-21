import Foundation
import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false
    
    init() {
        // Enable offline persistence with updated API
        setupFirestore()
        fetchBars()
    }
    
    private func setupFirestore() {
        // FIXED: Use the new cacheSettings API instead of deprecated properties
        let settings = FirestoreSettings()
        
        // Create cache settings with the new API
        let cacheSettings = MemoryCacheSettings()
        settings.cacheSettings = cacheSettings
        
        db.settings = settings
        
        // Listen for network connectivity changes
        db.addSnapshotsInSyncListener {
            DispatchQueue.main.async {
                self.isOffline = false
                print("🌐 Firestore: Back online")
            }
        }
        
        print("✅ Firestore configured with updated cache settings")
    }
    
    // MARK: - Bar Creation and Deletion
    
    func createBar(_ bar: Bar, completion: @escaping (Bool, String) -> Void) {
        let barData = bar.toDictionary()
        
        db.collection("bars").document(bar.id).setData(barData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error creating bar: \(error.localizedDescription)")
                    
                    // Check if it's a network error
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                        self?.isOffline = true
                        completion(false, "You're offline. The bar will be created when you reconnect.")
                    } else {
                        completion(false, "Failed to create bar: \(error.localizedDescription)")
                    }
                } else {
                    print("✅ Successfully created bar: \(bar.name)")
                    completion(true, "Bar created successfully!")
                }
            }
        }
    }
    
    func deleteBar(barId: String, completion: @escaping (Bool, String) -> Void) {
        let barRef = db.collection("bars").document(barId)
        
        barRef.delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error deleting bar: \(error.localizedDescription)")
                    
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                        self?.isOffline = true
                        completion(false, "You're offline. The bar will be deleted when you reconnect.")
                    } else {
                        completion(false, "Failed to delete bar: \(error.localizedDescription)")
                    }
                } else {
                    print("✅ Successfully deleted bar")
                    completion(true, "Bar deleted successfully")
                }
            }
        }
    }
    
    // MARK: - Bar Data Operations with Enhanced Error Handling
    
    func fetchBars() {
        isLoading = true
        errorMessage = nil
        
        db.collection("bars").addSnapshotListener { [weak self] querySnapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Firestore fetch error: \(error.localizedDescription)")
                    
                    // Handle specific error types
                    if error.localizedDescription.contains("offline") ||
                       error.localizedDescription.contains("network") ||
                       error.localizedDescription.contains("Backend didn't respond") {
                        self?.isOffline = true
                        self?.errorMessage = "You're offline. Using cached data."
                        print("📱 Using offline/cached data")
                    } else {
                        self?.errorMessage = "Error fetching bars: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self?.bars = []
                    return
                }
                
                // Successfully connected
                self?.isOffline = false
                self?.errorMessage = nil
                
                self?.bars = documents.compactMap { document in
                    Bar.fromDictionary(document.data(), documentId: document.documentID)
                }
                
                print("✅ Successfully fetched \(self?.bars.count ?? 0) bars")
            }
        }
    }
    
    func updateBarWithAutoTransition(bar: Bar) {
        let barRef = db.collection("bars").document(bar.id)
        let barData = bar.toDictionary()
        
        barRef.updateData(barData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase update error: \(error.localizedDescription)")
                    
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                        self?.isOffline = true
                        self?.errorMessage = "You're offline. Changes will sync when you reconnect."
                    } else {
                        self?.errorMessage = "Error updating bar: \(error.localizedDescription)"
                    }
                } else {
                    self?.isOffline = false
                    self?.errorMessage = nil
                    print("✅ Successfully updated \(bar.name) in Firebase")
                    if bar.isAutoTransitionActive {
                        print("   ⏰ Auto-transition active: \(bar.status.displayName) → \(bar.pendingStatus?.displayName ?? "unknown")")
                    }
                }
            }
        }
    }
    
    // MARK: - Connection Status
    
    func checkConnection() {
        // Simple connectivity check
        db.collection("bars").limit(to: 1).getDocuments { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    if error.localizedDescription.contains("offline") || error.localizedDescription.contains("network") {
                        self?.isOffline = true
                    }
                } else {
                    self?.isOffline = false
                }
            }
        }
    }
    
    // MARK: - 7-Day Schedule Management
    
    func updateBarSchedule(barId: String, weeklySchedule: WeeklySchedule) {
        let barRef = db.collection("bars").document(barId)
        
        barRef.updateData([
            "weeklySchedule": weeklySchedule.toDictionary(),
            "lastUpdated": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error updating schedule: \(error.localizedDescription)"
                }
                print("❌ Firebase schedule update error: \(error.localizedDescription)")
            } else {
                print("✅ Successfully updated 7-day schedule for bar: \(barId)")
            }
        }
    }
    
    // MARK: - Other Bar Property Updates
    
    func updateBarDescription(barId: String, newDescription: String) {
        let barRef = db.collection("bars").document(barId)
        
        barRef.updateData([
            "description": newDescription,
            "lastUpdated": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error updating description: \(error.localizedDescription)"
                }
            } else {
                print("✅ Successfully updated description for bar: \(barId)")
            }
        }
    }
    
    // DEPRECATED: Use updateBarSchedule instead
    func updateBarOperatingHours(barId: String, operatingHours: OperatingHours) {
        print("⚠️ Deprecated method called: updateBarOperatingHours. This method is no longer used with the 7-day schedule system.")
        
        // For backward compatibility, just update timestamp
        let barRef = db.collection("bars").document(barId)
        
        barRef.updateData([
            "lastUpdated": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error updating timestamp: \(error.localizedDescription)"
                }
            } else {
                print("✅ Updated timestamp for bar: \(barId) (deprecated operating hours call)")
            }
        }
    }
    
    func updateBarPassword(barId: String, newPassword: String) {
        let barRef = db.collection("bars").document(barId)
        
        barRef.updateData([
            "password": newPassword,
            "lastUpdated": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error updating password: \(error.localizedDescription)"
                }
            } else {
                print("✅ Successfully updated password for bar: \(barId)")
            }
        }
    }
    
    func updateBarSocialLinks(barId: String, socialLinks: SocialLinks) {
        let barRef = db.collection("bars").document(barId)
        
        let socialLinksData: [String: String] = [
            "instagram": socialLinks.instagram,
            "twitter": socialLinks.twitter,
            "facebook": socialLinks.facebook,
            "website": socialLinks.website
        ]
        
        barRef.updateData([
            "socialLinks": socialLinksData,
            "lastUpdated": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error updating social links: \(error.localizedDescription)"
                }
            } else {
                print("✅ Successfully updated social links for bar: \(barId)")
            }
        }
    }
    
    // MARK: - Authentication
    
    func authenticateBarOwner(barName: String, password: String, completion: @escaping (Result<Bar, Error>) -> Void) {
        if let bar = bars.first(where: { $0.username.lowercased() == barName.lowercased() && $0.password == password }) {
            completion(.success(bar))
        } else {
            completion(.failure(AuthError.invalidCredentials))
        }
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid bar name or password"
        }
    }
}
