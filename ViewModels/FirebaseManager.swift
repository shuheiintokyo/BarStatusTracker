import Foundation
import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Published property to track favorite counts for all bars
    @Published var favoriteCounts: [String: Int] = [:]
    
    // Basic device analytics
    private let deviceAnalytics = BasicDeviceAnalytics()
    
    init() {
        setupInitialData()
        setupFavoriteCountsListener()
        
        // Try to get location (optional)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.deviceAnalytics.requestLocationPermission()
        }
    }
    
    // MARK: - Bar Creation and Deletion
    
    func createBar(_ bar: Bar, completion: @escaping (Bool, String) -> Void) {
        let barData = bar.toDictionary()
        
        db.collection("bars").document(bar.id).setData(barData) { error in
            if let error = error {
                print("❌ Error creating bar: \(error.localizedDescription)")
                completion(false, "Failed to create bar: \(error.localizedDescription)")
            } else {
                print("✅ Successfully created bar: \(bar.name)")
                completion(true, "Bar created successfully!")
            }
        }
    }
    
    func deleteBar(barId: String, completion: @escaping (Bool, String) -> Void) {
        let barRef = db.collection("bars").document(barId)
        
        // First delete all favorites for this bar
        db.collection("favorites")
            .whereField("barId", isEqualTo: barId)
            .getDocuments { [weak self] querySnapshot, error in
                
                if let error = error {
                    print("❌ Error fetching favorites for deletion: \(error.localizedDescription)")
                    completion(false, "Failed to delete bar: \(error.localizedDescription)")
                    return
                }
                
                // Delete all favorite documents
                let batch = self?.db.batch()
                querySnapshot?.documents.forEach { document in
                    batch?.deleteDocument(document.reference)
                }
                
                // Commit favorite deletions
                batch?.commit { error in
                    if let error = error {
                        print("❌ Error deleting favorites: \(error.localizedDescription)")
                        completion(false, "Failed to delete bar favorites: \(error.localizedDescription)")
                        return
                    }
                    
                    // Now delete the bar itself
                    barRef.delete { error in
                        if let error = error {
                            print("❌ Error deleting bar: \(error.localizedDescription)")
                            completion(false, "Failed to delete bar: \(error.localizedDescription)")
                        } else {
                            print("✅ Successfully deleted bar and its favorites")
                            completion(true, "Bar deleted successfully")
                        }
                    }
                }
            }
    }
    
    // MARK: - Bar Data Operations
    
    func fetchBars() {
        isLoading = true
        
        db.collection("bars").addSnapshotListener { [weak self] querySnapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error fetching bars: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self?.errorMessage = "No bars found"
                    return
                }
                
                self?.bars = documents.compactMap { document in
                    Bar.fromDictionary(document.data(), documentId: document.documentID)
                }
            }
        }
    }
    
    func updateBarWithAutoTransition(bar: Bar) {
        let barRef = db.collection("bars").document(bar.id)
        let barData = bar.toDictionary()
        
        barRef.updateData(barData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error updating bar: \(error.localizedDescription)"
                }
                print("❌ Firebase update error: \(error.localizedDescription)")
            } else {
                print("✅ Successfully updated \(bar.name) in Firebase")
                if bar.isAutoTransitionActive {
                    print("   ⏰ Auto-transition active: \(bar.status.displayName) → \(bar.pendingStatus?.displayName ?? "unknown")")
                }
            }
        }
    }
    
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
    
    func updateBarOperatingHours(barId: String, operatingHours: OperatingHours) {
        let barRef = db.collection("bars").document(barId)
        
        barRef.updateData([
            "operatingHours": operatingHours.toDictionary(),
            "lastUpdated": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Error updating operating hours: \(error.localizedDescription)"
                }
            } else {
                print("✅ Successfully updated operating hours for bar: \(barId)")
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
    
    // MARK: - Enhanced Favorites System with Basic Analytics
    
    func toggleFavorite(barId: String, deviceId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // First check if favorite already exists
        db.collection("favorites")
            .whereField("barId", isEqualTo: barId)
            .whereField("deviceId", isEqualTo: deviceId)
            .getDocuments { [weak self] querySnapshot, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    // Favorite exists, check if it's active
                    let document = documents.first!
                    let data = document.data()
                    let isActive = data["isActive"] as? Bool ?? false
                    
                    // Toggle the active status
                    self?.updateFavoriteStatus(documentId: document.documentID, isActive: !isActive) { result in
                        switch result {
                        case .success:
                            completion(.success(!isActive))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    // No favorite exists, create new one with analytics
                    self?.createFavoriteWithBasicAnalytics(barId: barId, deviceId: deviceId) { result in
                        switch result {
                        case .success:
                            completion(.success(true))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
    }
    
    private func createFavoriteWithBasicAnalytics(barId: String, deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        // Basic favorite data
        var favoriteData: [String: Any] = [
            "barId": barId,
            "deviceId": deviceId,
            "isActive": true,
            "createdAt": Timestamp(date: Date()),
            "lastUpdated": Timestamp(date: Date())
        ]
        
        // Add device info (always available)
        favoriteData["deviceInfo"] = deviceAnalytics.deviceInfo.toDictionary()
        
        // Add location info (if available)
        if let locationInfo = deviceAnalytics.locationInfo {
            favoriteData["locationInfo"] = locationInfo.toDictionary()
            print("📍 Adding location to favorite: \(locationInfo.summary)")
        } else {
            print("📍 No location available (optional)")
        }
        
        db.collection("favorites").addDocument(data: favoriteData) { error in
            if let error = error {
                completion(.failure(error))
                print("❌ Error creating favorite: \(error.localizedDescription)")
            } else {
                completion(.success(()))
                print("✅ Successfully created favorite with analytics for bar: \(barId)")
                print("📱 Device: \(self.deviceAnalytics.deviceInfo.summary)")
            }
        }
    }
    
    private func updateFavoriteStatus(documentId: String, isActive: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("favorites").document(documentId).updateData([
            "isActive": isActive,
            "lastUpdated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
                print("❌ Error updating favorite status: \(error.localizedDescription)")
            } else {
                completion(.success(()))
                print("✅ Successfully updated favorite status to: \(isActive)")
            }
        }
    }
    
    func checkIfUserFavoritedBar(barId: String, deviceId: String, completion: @escaping (Bool) -> Void) {
        db.collection("favorites")
            .whereField("barId", isEqualTo: barId)
            .whereField("deviceId", isEqualTo: deviceId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { querySnapshot, error in
                
                if let error = error {
                    print("❌ Error checking favorite status: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let isFavorited = !(querySnapshot?.documents.isEmpty ?? true)
                completion(isFavorited)
            }
    }
    
    private func setupFavoriteCountsListener() {
        // Listen to all active favorites and count them by barId
        db.collection("favorites")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                
                if let error = error {
                    print("❌ Error listening to favorites: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
                // Count favorites by barId
                var counts: [String: Int] = [:]
                for document in documents {
                    let data = document.data()
                    if let barId = data["barId"] as? String {
                        counts[barId] = (counts[barId] ?? 0) + 1
                    }
                }
                
                DispatchQueue.main.async {
                    self?.favoriteCounts = counts
                    print("📊 Updated favorite counts: \(counts)")
                }
            }
    }
    
    func getFavoriteCount(for barId: String) -> Int {
        return favoriteCounts[barId] ?? 0
    }
    
    // MARK: - Basic Analytics for Bar Owners
    func getBasicAnalytics(for barId: String, completion: @escaping ([String: Any]) -> Void) {
        db.collection("favorites")
            .whereField("barId", isEqualTo: barId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { querySnapshot, error in
                
                guard let documents = querySnapshot?.documents else {
                    completion([:])
                    return
                }
                
                var analytics: [String: Any] = [:]
                var countries: [String: Int] = [:]
                var cities: [String: Int] = [:]
                var deviceTypes: [String: Int] = [:]
                
                for document in documents {
                    let data = document.data()
                    
                    // Count by location (if available)
                    if let locationInfo = data["locationInfo"] as? [String: Any] {
                        if let country = locationInfo["country"] as? String, !country.isEmpty {
                            countries[country] = (countries[country] ?? 0) + 1
                        }
                        if let city = locationInfo["city"] as? String, !city.isEmpty {
                            cities[city] = (cities[city] ?? 0) + 1
                        }
                    }
                    
                    // Count by device type
                    if let deviceInfo = data["deviceInfo"] as? [String: Any] {
                        if let deviceType = deviceInfo["deviceType"] as? String {
                            deviceTypes[deviceType] = (deviceTypes[deviceType] ?? 0) + 1
                        }
                    }
                }
                
                analytics = [
                    "totalFavorites": documents.count,
                    "countries": countries,
                    "cities": cities,
                    "deviceTypes": deviceTypes,
                    "hasLocationData": !countries.isEmpty,
                    "lastUpdated": Date()
                ]
                
                print("📊 Basic analytics for \(barId): \(analytics)")
                completion(analytics)
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
    
    // MARK: - Initial Data Setup
    
    private func setupInitialData() {
        db.collection("bars").getDocuments { [weak self] querySnapshot, error in
            if let error = error {
                print("Error checking for existing data: \(error)")
                return
            }
            
            // Always fetch bars, whether or not we add sample data
            self?.fetchBars()
            
            // Only add sample data if completely empty (for new installations)
            if querySnapshot?.documents.isEmpty == true {
                print("🆕 First time setup - adding sample bars")
                self?.addSampleBars()
            }
        }
    }
    
    private func addSampleBars() {
        let sampleBars = [
            Bar(name: "The Cozy Corner", latitude: 35.6762, longitude: 139.6503, address: "123 Shibuya, Tokyo", status: .open, description: "A warm, welcoming neighborhood bar with craft cocktails and local beer.", username: "The Cozy Corner", password: "1234"),
            Bar(name: "Sunset Tavern", latitude: 35.6586, longitude: 139.7454, address: "456 Ginza, Tokyo", status: .closingSoon, description: "Perfect spot to watch the sunset with friends.", username: "Sunset Tavern", password: "5678"),
            Bar(name: "The Underground", latitude: 35.7090, longitude: 139.7319, address: "789 Shinjuku, Tokyo", status: .closed, description: "Speakeasy-style bar with vintage cocktails.", username: "The Underground", password: "9012")
        ]
        
        for bar in sampleBars {
            db.collection("bars").document(bar.id).setData(bar.toDictionary()) { error in
                if let error = error {
                    print("Error adding sample bar \(bar.name): \(error)")
                } else {
                    print("Added sample bar: \(bar.name)")
                }
            }
        }
    }
    
    // MARK: - Add this method to FirebaseManager.swift

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



