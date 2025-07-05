import SwiftUI

class BarViewModel: ObservableObject {
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var selectedBar: Bar?
    @Published var showingDetail = false
    
    // Authentication properties
    @Published var loggedInBar: Bar? = nil
    @Published var isOwnerMode = false
    
    // Firebase manager
    private let firebaseManager = FirebaseManager()
    
    // Biometric authentication manager
    private var biometricAuth = BiometricAuthManager()
    
    init() {
        setupFirebaseConnection()
    }
    
    // MARK: - Firebase Integration
    
    private func setupFirebaseConnection() {
        // Connect to Firebase data
        firebaseManager.$bars
            .receive(on: DispatchQueue.main)
            .assign(to: &$bars)
        
        firebaseManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        // Setup biometric auth
        setupBiometricAuth()
    }
    
    // Setup biometric authentication
    private func setupBiometricAuth() {
        // Check if there are saved credentials
        if biometricAuth.savedBarID != nil {
            // Auto-login will be handled by the UI when user chooses biometric option
        }
    }
    
    // MARK: - Authentication
    
    // Traditional username/password authentication
    func authenticateBar(username: String, password: String) -> Bool {
        // Use Firebase authentication
        firebaseManager.authenticateBarOwner(barName: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let bar):
                    self?.loggedInBar = bar
                    self?.isOwnerMode = true
                    // Save credentials for future biometric authentication
                    self?.biometricAuth.saveCredentials(barID: bar.id, barName: bar.name)
                case .failure:
                    break // Handle error in UI
                }
            }
        }
        
        // Return temporary result - real result comes via the completion handler
        return firebaseManager.bars.contains { $0.username.lowercased() == username.lowercased() && $0.password == password }
    }
    
    // Biometric authentication
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        biometricAuth.authenticateWithBiometrics { [weak self] success, error in
            if success, let savedBarID = self?.biometricAuth.savedBarID {
                // Find the bar with the saved ID
                if let bar = self?.bars.first(where: { $0.id == savedBarID }) {
                    self?.loggedInBar = bar
                    self?.isOwnerMode = true
                    completion(true, nil)
                } else {
                    // Saved bar not found, clear credentials
                    self?.biometricAuth.clearCredentials()
                    completion(false, "Saved bar not found")
                }
            } else {
                completion(false, error)
            }
        }
    }
    
    // Check if biometric authentication is available and set up
    var canUseBiometricAuth: Bool {
        return biometricAuth.savedBarID != nil && biometricAuth.biometricType != .none
    }
    
    // Get biometric authentication info for UI
    var biometricAuthInfo: (iconName: String, displayName: String) {
        return (biometricAuth.biometricIconName, biometricAuth.biometricDisplayName)
    }
    
    // Logout function
    func logout() {
        loggedInBar = nil
        isOwnerMode = false
    }
    
    // Full logout (clears biometric credentials too)
    func fullLogout() {
        loggedInBar = nil
        isOwnerMode = false
        biometricAuth.clearCredentials()
    }
    
    // Switch to guest view (stay logged in but show all bars)
    func switchToGuestView() {
        isOwnerMode = false
    }
    
    // Switch back to owner view
    func switchToOwnerView() {
        if loggedInBar != nil {
            isOwnerMode = true
        }
    }
    
    // Check if current user can edit this bar
    func canEdit(bar: Bar) -> Bool {
        guard let loggedInBar = loggedInBar else { return false }
        return loggedInBar.id == bar.id
    }
    
    // MARK: - Firebase Data Operations
    
    // Update bar status (only if owner) - now uses Firebase
    func updateBarStatus(_ bar: Bar, newStatus: BarStatus) {
        guard canEdit(bar: bar) else { return }
        
        // Update in Firebase
        firebaseManager.updateBarStatus(barId: bar.id, newStatus: newStatus)
        
        // Update local logged-in bar reference
        if loggedInBar?.id == bar.id {
            loggedInBar?.status = newStatus
            loggedInBar?.lastUpdated = Date()
        }
    }
    
    // Update bar description (only if owner) - now uses Firebase
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        guard canEdit(bar: bar) else { return }
        
        // Update in Firebase
        firebaseManager.updateBarDescription(barId: bar.id, newDescription: newDescription)
        
        // Update local logged-in bar reference
        if loggedInBar?.id == bar.id {
            loggedInBar?.description = newDescription
            loggedInBar?.lastUpdated = Date()
        }
    }
    
    // Get all bars for general users
    func getAllBars() -> [Bar] {
        return bars
    }
    
    // Get only the logged-in bar for owners
    func getOwnerBars() -> [Bar] {
        guard let loggedInBar = loggedInBar else { return [] }
        // Find the most up-to-date version of the logged-in bar from Firebase
        if let currentBar = bars.first(where: { $0.id == loggedInBar.id }) {
            return [currentBar]
        }
        return [loggedInBar]
    }
}

