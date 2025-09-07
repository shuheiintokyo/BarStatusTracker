import SwiftUI
import Combine

// MARK: - Fixed BarViewModel with Proper Schedule Refresh

class BarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var selectedBar: Bar?
    @Published var showingDetail = false
    @Published var loggedInBar: Bar? = nil
    @Published var isOwnerMode = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let firebaseManager: FirebaseManager
    private let biometricManager: BiometricAuthManager
    private var cancellables = Set<AnyCancellable>()
    private var statusUpdateTimer: Timer?
    private var scheduleRefreshTimer: Timer?
    
    // MARK: - Initialization
    init(firebaseManager: FirebaseManager = FirebaseManager(),
         biometricManager: BiometricAuthManager = BiometricAuthManager()) {
        self.firebaseManager = firebaseManager
        self.biometricManager = biometricManager
        
        setupBindings()
        startPeriodicUpdates()
        startScheduleRefresh()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind Firebase manager to local state with immediate schedule refresh
        firebaseManager.$bars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newBars in
                // FIXED: Properly refresh schedules when bars are loaded
                self?.bars = newBars.compactMap { bar in
                    var refreshedBar = bar
                    if refreshedBar.refreshScheduleIfNeeded() {
                        // Schedule was refreshed, update in Firebase
                        self?.updateBarInFirebaseAsync(refreshedBar)
                    }
                    return refreshedBar
                }
            }
            .store(in: &cancellables)
        
        firebaseManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        firebaseManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
        
        // Update logged in bar reference when bars change
        firebaseManager.$bars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bars in
                self?.updateLoggedInBarReference(from: bars)
                self?.processAutoTransitions(for: bars)
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpdates() {
        // Update schedule-based statuses every minute
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshScheduleBasedStatuses()
            }
        }
    }
    
    // FIXED: Improved schedule refresh timer
    private func startScheduleRefresh() {
        // Check for stale schedules every hour
        scheduleRefreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshAllScheduleDates()
            }
        }
        
        // Also refresh on app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        DispatchQueue.main.async {
            self.refreshAllScheduleDates()
        }
    }
    
    // FIXED: Proper schedule date refresh
    private func refreshAllScheduleDates() {
        print("🔄 Refreshing all schedule dates...")
        var hasChanges = false
        
        for i in 0..<bars.count {
            var bar = bars[i]
            if bar.refreshScheduleIfNeeded() {
                print("📅 Updated schedule dates for bar: \(bar.name)")
                bars[i] = bar
                hasChanges = true
                
                // Update in Firebase asynchronously
                updateBarInFirebaseAsync(bar)
            }
        }
        
        // Update logged in bar if needed
        if let loggedInBarId = loggedInBar?.id,
           let updatedBar = bars.first(where: { $0.id == loggedInBarId }) {
            var refreshedLoggedInBar = updatedBar
            if refreshedLoggedInBar.refreshScheduleIfNeeded() {
                loggedInBar = refreshedLoggedInBar
                updateBarInFirebaseAsync(refreshedLoggedInBar)
                hasChanges = true
            } else {
                loggedInBar = updatedBar
            }
        }
        
        // Only trigger UI update if there were actual changes
        if hasChanges {
            print("✅ Schedule refresh complete with changes")
            objectWillChange.send()
        }
    }
    
    deinit {
        statusUpdateTimer?.invalidate()
        scheduleRefreshTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Bar Management
    
    func createNewBar(_ bar: Bar, enableFaceID: Bool, completion: @escaping (Bool, String) -> Void) {
        firebaseManager.createBar(bar) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    if enableFaceID {
                        self?.biometricManager.saveCredentials(barID: bar.id, barName: bar.name)
                        self?.loggedInBar = bar
                        self?.isOwnerMode = true
                    }
                    completion(true, "Bar created successfully!")
                } else {
                    completion(false, message)
                }
            }
        }
    }
    
    func deleteBar(_ bar: Bar, completion: @escaping (Bool, String) -> Void) {
        guard canEdit(bar: bar) else {
            completion(false, "You don't have permission to delete this bar")
            return
        }
        
        firebaseManager.deleteBar(barId: bar.id) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    if self?.loggedInBar?.id == bar.id {
                        self?.logout()
                    }
                    completion(true, "Bar deleted successfully")
                } else {
                    completion(false, message)
                }
            }
        }
    }
    
    // MARK: - Status Management
    
    func setManualBarStatus(_ bar: Bar, newStatus: BarStatus) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.setManualStatus(newStatus)
        
        updateBarInFirebase(updatedBar)
    }
    
    func setBarToFollowSchedule(_ bar: Bar) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.followSchedule()
        
        updateBarInFirebase(updatedBar)
    }
    
    func updateBarSchedule(_ bar: Bar, newSchedule: WeeklySchedule) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.updateSchedule(newSchedule)
        
        updateBarInFirebase(updatedBar)
    }
    
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.description = newDescription
        updatedBar.lastUpdated = Date()
        
        updateBarInFirebase(updatedBar)
    }
    
    func updateBarPassword(_ bar: Bar, newPassword: String) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.password = newPassword
        updatedBar.lastUpdated = Date()
        
        updateBarInFirebase(updatedBar)
    }
    
    func updateBarSocialLinks(_ bar: Bar, newSocialLinks: SocialLinks) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.socialLinks = newSocialLinks
        updatedBar.lastUpdated = Date()
        
        updateBarInFirebase(updatedBar)
    }
    
    func setAutoTransition(for bar: Bar, to status: BarStatus, at time: Date) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.setAutoTransition(to: status, at: time)
        
        updateBarInFirebase(updatedBar)
    }
    
    func cancelAutoTransition(for bar: Bar) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.clearAutoTransition()
        
        updateBarInFirebase(updatedBar)
    }
    
    // MARK: - Authentication
    
    func authenticateBar(username: String, password: String) -> Bool {
        let matchingBar = bars.first {
            $0.username.lowercased() == username.lowercased() && $0.password == password
        }
        
        if let bar = matchingBar {
            loggedInBar = bar
            isOwnerMode = true
            biometricManager.saveCredentials(barID: bar.id, barName: bar.name)
            return true
        }
        
        return false
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        guard biometricManager.isAvailable else {
            completion(false, "Biometric authentication not available")
            return
        }
        
        biometricManager.authenticateWithBiometrics { [weak self] success, error in
            DispatchQueue.main.async {
                if success, let barID = self?.biometricManager.savedBarID {
                    if let bar = self?.bars.first(where: { $0.id == barID }) {
                        self?.loggedInBar = bar
                        self?.isOwnerMode = true
                        completion(true, nil)
                    } else {
                        completion(false, "Saved bar no longer exists")
                    }
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    func logout() {
        isOwnerMode = false
        loggedInBar = nil
    }
    
    func fullLogout() {
        logout()
        biometricManager.clearCredentials()
    }
    
    func switchToGuestView() {
        isOwnerMode = false
        // Keep loggedInBar for potential quick return
    }
    
    // MARK: - Helper Methods
    
    func canEdit(bar: Bar) -> Bool {
        return loggedInBar?.id == bar.id
    }
    
    var canUseBiometricAuth: Bool {
        return biometricManager.biometricType != .none
    }
    
    var biometricAuthInfo: (iconName: String, displayName: String) {
        return (biometricManager.biometricIconName, biometricManager.biometricDisplayName)
    }
    
    func isValidBiometricBar() -> Bool {
        return biometricManager.isAvailable
    }
    
    // MARK: - Data Access - FIXED: Return bars with automatically refreshed schedules
    
    func getAllBars() -> [Bar] {
        return bars.map { bar in
            var refreshedBar = bar
            let _ = refreshedBar.refreshScheduleIfNeeded()
            return refreshedBar
        }
    }
    
    func getOwnerBars() -> [Bar] {
        guard let loggedInBar = loggedInBar else { return [] }
        return getAllBars().filter { $0.id == loggedInBar.id }
    }
    
    func getBarsOpenNow() -> [Bar] {
        return getAllBars().filter { $0.status == .open || $0.status == .openingSoon }
    }
    
    func getBarsOpenToday() -> [Bar] {
        return getAllBars().filter { $0.isOpenToday }
    }
    
    func forceRefreshAllData() {
        refreshAllScheduleDates()
        firebaseManager.fetchBars()
    }
    
    // MARK: - Auto-transition Support
    
    func getTimeRemainingText(for bar: Bar) -> String? {
        guard bar.isAutoTransitionActive,
              let transitionTime = bar.transitionTime else {
            return nil
        }
        
        let now = Date()
        let timeInterval = transitionTime.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Now"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Private Methods
    
    private func updateBarInFirebase(_ bar: Bar) {
        // Update local state immediately for responsive UI
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index] = bar
        }
        
        if loggedInBar?.id == bar.id {
            loggedInBar = bar
        }
        
        // Persist to Firebase
        firebaseManager.updateBarWithAutoTransition(bar: bar)
    }
    
    // FIXED: Add async Firebase update method for schedule refreshes
    private func updateBarInFirebaseAsync(_ bar: Bar) {
        // Update local state immediately
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index] = bar
        }
        
        if loggedInBar?.id == bar.id {
            loggedInBar = bar
        }
        
        // Persist to Firebase asynchronously (don't block UI)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.firebaseManager.updateBarWithAutoTransition(bar: bar)
        }
    }
    
    private func updateLoggedInBarReference(from bars: [Bar]) {
        guard let loggedInBarId = loggedInBar?.id else { return }
        if let updatedBar = bars.first(where: { $0.id == loggedInBarId }) {
            var refreshedBar = updatedBar
            let _ = refreshedBar.refreshScheduleIfNeeded()
            loggedInBar = refreshedBar
        }
    }
    
    private func refreshScheduleBasedStatuses() {
        // FIXED: Only refresh if needed to avoid unnecessary updates
        let startTime = Date()
        refreshAllScheduleDates()
        let endTime = Date()
        
        let refreshTime = endTime.timeIntervalSince(startTime)
        if refreshTime > 0.1 { // Only log if refresh took significant time
            print("⏱️ Schedule refresh took \(String(format: "%.2f", refreshTime))s")
        }
        
        objectWillChange.send()
    }
    
    private func processAutoTransitions(for bars: [Bar]) {
        let now = Date()
        
        for bar in bars {
            if bar.isAutoTransitionActive,
               let transitionTime = bar.transitionTime,
               let pendingStatus = bar.pendingStatus,
               now >= transitionTime {
                
                // Execute the auto-transition
                var updatedBar = bar
                updatedBar.setManualStatus(pendingStatus)
                updatedBar.clearAutoTransition()
                
                updateBarInFirebase(updatedBar)
            }
        }
    }
}

// MARK: - Error Types

enum BarViewModelError: Error, LocalizedError {
    case unauthorized
    case notFound
    case invalidData
    case biometricNotAvailable
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .notFound:
            return "Bar not found"
        case .invalidData:
            return "Invalid bar data"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
