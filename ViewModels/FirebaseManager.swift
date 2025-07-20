import Foundation
import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        fetchBars()
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
        
        barRef.delete { error in
            if let error = error {
                print("❌ Error deleting bar: \(error.localizedDescription)")
                completion(false, "Failed to delete bar: \(error.localizedDescription)")
            } else {
                print("✅ Successfully deleted bar")
                completion(true, "Bar deleted successfully")
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
                    self?.bars = [] // Empty array if no bars found
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
