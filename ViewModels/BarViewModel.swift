import SwiftUI
import Combine

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
    
    // User preferences manager for favorites
    @Published var userPreferencesManager = UserPreferencesManager()
    
    // Timer for checking auto-transitions (more frequent)
    private var autoTransitionTimer: Timer?
    
    // Timer for UI updates (every second)
    private var uiUpdateTimer: Timer?
    
    init() {
        setupFirebaseConnection()
        startAutoTransitionMonitoring()
        startUIUpdateTimer()
        
        // Connect user preferences to Firebase manager
        userPreferencesManager.setFirebaseManager(firebaseManager)
    }
    
    deinit {
        autoTransitionTimer?.invalidate()
        uiUpdateTimer?.invalidate()
    }
    
    // MARK: - Timer Management
    
    private func startAutoTransitionMonitoring() {
        // Check for auto-transitions every 10 seconds (more frequent)
        autoTransitionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkForAutoTransitions()
        }
    }
    
    private func startUIUpdateTimer() {
        // Update UI every second for real-time countdown
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send() // Force UI update
            }
        }
    }
    
    private func checkForAutoTransitions() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let barsNeedingTransition = self.bars.filter { $0.shouldAutoTransition }
            
            if barsNeedingTransition.count > 0 {
                print("🔄 Found \(barsNeedingTransition.count) bars needing auto-transition")
            }
            
            for var bar in barsNeedingTransition {
                let oldStatus = bar.status
                if bar.executeAutoTransition() {
                    print("🔄 Auto-transitioning \(bar.name) from \(oldStatus.displayName) to \(bar.status.displayName)")
                    
                    // Update in Firebase
                    self.firebaseManager.updateBarWithAutoTransition(bar: bar)
                    
                    // Update local logged-in bar reference if needed
                    if self.loggedInBar?.id == bar.id {
                        self.loggedInBar = bar
                    }
                    
                    // Force UI refresh
                    self.objectWillChange.send()
                    
                    print("✅ \(bar.name) successfully changed to \(bar.status.displayName)")
                }
            }
        }
    }
    
    // MARK: - Firebase Integration
    
    private func setupFirebaseConnection() {
        // Connect to Firebase data
        firebaseManager.$bars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bars in
                self?.bars = bars
                // Sync favorite statuses when bars are loaded
                self?.syncFavoritesForAllBars()
            }
            .store(in: &cancellables)
        
        firebaseManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        // Setup biometric auth
        setupBiometricAuth()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func syncFavoritesForAllBars() {
        let barIds = bars.map { $0.id }
        userPreferencesManager.syncAllFavoriteStatuses(for: barIds)
    }
    
    // Setup biometric authentication
    private func setupBiometricAuth() {
        if biometricAuth.savedBarID != nil {
            // Auto-login will be handled by the UI when user chooses biometric option
        }
    }
    
    // MARK: - Authentication
    
    func authenticateBar(username: String, password: String) -> Bool {
        firebaseManager.authenticateBarOwner(barName: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let bar):
                    self?.loggedInBar = bar
                    self?.isOwnerMode = true
                    self?.biometricAuth.saveCredentials(barID: bar.id, barName: bar.name)
                case .failure:
                    break
                }
            }
        }
        
        return firebaseManager.bars.contains { $0.username.lowercased() == username.lowercased() && $0.password == password }
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        biometricAuth.authenticateWithBiometrics { [weak self] success, error in
            if success, let savedBarID = self?.biometricAuth.savedBarID {
                if let bar = self?.bars.first(where: { $0.id == savedBarID }) {
                    self?.loggedInBar = bar
                    self?.isOwnerMode = true
                    completion(true, nil)
                } else {
                    self?.biometricAuth.clearCredentials()
                    completion(false, "Saved bar not found")
                }
            } else {
                completion(false, error)
            }
        }
    }
    
    var canUseBiometricAuth: Bool {
        return biometricAuth.savedBarID != nil && biometricAuth.biometricType != .none
    }
    
    var biometricAuthInfo: (iconName: String, displayName: String) {
        return (biometricAuth.biometricIconName, biometricAuth.biometricDisplayName)
    }
    
    func logout() {
        loggedInBar = nil
        isOwnerMode = false
    }
    
    func fullLogout() {
        loggedInBar = nil
        isOwnerMode = false
        biometricAuth.clearCredentials()
    }
    
    func switchToGuestView() {
        isOwnerMode = false
    }
    
    func switchToOwnerView() {
        if loggedInBar != nil {
            isOwnerMode = true
        }
    }
    
    func canEdit(bar: Bar) -> Bool {
        guard let loggedInBar = loggedInBar else { return false }
        return loggedInBar.id == bar.id
    }
    
    // MARK: - Status Operations (Simplified)
    
    func updateBarStatus(_ bar: Bar, newStatus: BarStatus) {
        guard canEdit(bar: bar) else { return }
        
        let oldStatus = bar.status
        var updatedBar = bar
        
        // Cancel any existing auto-transition
        updatedBar.cancelAutoTransition()
        
        // Check if this status should trigger an auto-transition
        switch newStatus {
        case .openingSoon:
            updatedBar.status = .openingSoon
            updatedBar.startAutoTransition(to: .open, in: 1) // 1 minute for testing
            print("🕐 \(bar.name) set to Opening Soon - will auto-open in 1 minute")
            
        case .closingSoon:
            updatedBar.status = .closingSoon
            updatedBar.startAutoTransition(to: .closed, in: 1) // 1 minute for testing
            print("🕐 \(bar.name) set to Closing Soon - will auto-close in 1 minute")
            
        case .open, .closed:
            updatedBar.status = newStatus
            print("✋ \(bar.name) manually set to \(newStatus.displayName)")
        }
        
        // Update in Firebase
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        
        // Update local logged-in bar reference
        if loggedInBar?.id == bar.id {
            loggedInBar = updatedBar
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    func cancelAutoTransition(for bar: Bar) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.cancelAutoTransition()
        
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        
        if loggedInBar?.id == bar.id {
            loggedInBar = updatedBar
        }
        
        objectWillChange.send()
        print("❌ Auto-transition cancelled for \(bar.name)")
    }
    
    // Get time remaining for auto-transition (for UI display)
    func getTimeRemainingText(for bar: Bar) -> String? {
        guard let timeRemaining = bar.timeUntilAutoTransition,
              timeRemaining > 0 else {
            return nil
        }
        
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    // MARK: - Firebase-Integrated Favorites System
    
    func toggleFavorite(barId: String) {
        userPreferencesManager.toggleFavorite(barId: barId) { [weak self] isNowFavorited in
            // The UI will automatically update through @Published properties
            // Optionally trigger an additional UI refresh
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
            
            print("🔄 Favorite toggle completed for \(barId): \(isNowFavorited)")
        }
    }
    
    func getFavoriteCount(for barId: String) -> Int {
        // Get real count from Firebase
        return firebaseManager.getFavoriteCount(for: barId)
    }
    
    func isFavorite(barId: String) -> Bool {
        return userPreferencesManager.isFavorite(barId: barId)
    }
    
    // MARK: - Data Operations
    
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarDescription(barId: bar.id, newDescription: newDescription)
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.description = newDescription
            loggedInBar?.lastUpdated = Date()
        }
    }
    
    func getAllBars() -> [Bar] {
        return bars
    }
    
    func getOwnerBars() -> [Bar] {
        guard let loggedInBar = loggedInBar else { return [] }
        if let currentBar = bars.first(where: { $0.id == loggedInBar.id }) {
            return [currentBar]
        }
        return [loggedInBar]
    }
    
    // MARK: - Debug Methods
    
    func debugFavorites() {
        userPreferencesManager.debugPrintStatus()
        print("📊 Firebase favorite counts: \(firebaseManager.favoriteCounts)")
    }
}
