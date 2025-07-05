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
    
    init() {
        setupInitialData()
        setupFavoriteCountsListener()
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
            }
        }
    }
    
    // MARK: - Favorites System
    
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
                    // No favorite exists, create new one
                    self?.createFavorite(barId: barId, deviceId: deviceId) { result in
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
    
    private func createFavorite(barId: String, deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let favoriteData: [String: Any] = [
            "barId": barId,
            "deviceId": deviceId,
            "isActive": true,
            "createdAt": Timestamp(date: Date()),
            "lastUpdated": Timestamp(date: Date())
        ]
        
        db.collection("favorites").addDocument(data: favoriteData) { error in
            if let error = error {
                completion(.failure(error))
                print("❌ Error creating favorite: \(error.localizedDescription)")
            } else {
                completion(.success(()))
                print("✅ Successfully created favorite for bar: \(barId)")
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
            
            if querySnapshot?.documents.isEmpty == true {
                self?.addSampleBars()
            }
            
            self?.fetchBars()
        }
    }
    
    private func addSampleBars() {
        let sampleBars = [
            Bar(name: "The Cozy Corner", latitude: 35.6762, longitude: 139.6503, address: "123 Shibuya, Tokyo", status: .open, description: "A warm, welcoming neighborhood bar with craft cocktails and local beer.", password: "1234"),
            Bar(name: "Sunset Tavern", latitude: 35.6586, longitude: 139.7454, address: "456 Ginza, Tokyo", status: .closingSoon, description: "Perfect spot to watch the sunset with friends.", password: "5678"),
            Bar(name: "The Underground", latitude: 35.7090, longitude: 139.7319, address: "789 Shinjuku, Tokyo", status: .closed, description: "Speakeasy-style bar with vintage cocktails.", password: "9012"),
            Bar(name: "Harbor Lights", latitude: 35.6284, longitude: 139.7384, address: "321 Minato, Tokyo", status: .openingSoon, description: "Waterfront bar with live music every weekend.", password: "3456"),
            Bar(name: "City View Lounge", latitude: 35.6938, longitude: 139.7036, address: "654 Harajuku, Tokyo", status: .open, description: "Rooftop bar with panoramic city views.", password: "7890"),
            Bar(name: "The Local Pub", latitude: 35.7023, longitude: 139.7745, address: "987 Asakusa, Tokyo", status: .closed, description: "Traditional pub with hearty food and cold beer.", password: "2468")
        ]
        
        for bar in sampleBars {
            db.collection("bars").document(bar.id).setData(bar.toDictionary()) { error in
                if let error = error {
                    print("Error adding bar \(bar.name): \(error)")
                } else {
                    print("Added bar: \(bar.name)")
                }
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
