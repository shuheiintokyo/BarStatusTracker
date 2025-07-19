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
    
    // Notification manager
    @Published var notificationManager: NotificationManager?
    
    // Enhanced timers for schedule and auto-transition monitoring
    private var scheduleMonitoringTimer: Timer?
    private var autoTransitionTimer: Timer?
    private var uiUpdateTimer: Timer?
    
    init() {
        setupFirebaseConnection()
        startScheduleMonitoring()  // NEW: Monitor schedule-based status changes
        startAutoTransitionMonitoring()
        startUIUpdateTimer()
        
        userPreferencesManager.setFirebaseManager(firebaseManager)
    }
    
    deinit {
        scheduleMonitoringTimer?.invalidate()
        autoTransitionTimer?.invalidate()
        uiUpdateTimer?.invalidate()
    }
    
    // MARK: - Enhanced Status Management
    
    func setManualBarStatus(_ bar: Bar, newStatus: BarStatus) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        let oldStatus = bar.status
        
        // Set manual status (this overrides schedule)
        updatedBar.setManualStatus(newStatus)
        
        print("📱 Manual status set for \(bar.name): \(newStatus.displayName)")
        
        // Update in Firebase
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        
        // Update local logged-in bar reference
        if loggedInBar?.id == bar.id {
            loggedInBar = updatedBar
        }
        
        // Send notification if status actually changed
        if oldStatus != newStatus {
            sendStatusChangeNotification(bar: updatedBar, oldStatus: oldStatus, newStatus: newStatus)
        }
        
        objectWillChange.send()
    }
    
    func setBarToFollowSchedule(_ bar: Bar) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        let oldStatus = bar.status
        
        // Set to follow schedule
        updatedBar.followSchedule()
        let newStatus = updatedBar.status  // This will now be schedule-based
        
        print("📅 \(bar.name) now following schedule: \(newStatus.displayName)")
        
        // Update in Firebase
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        
        // Update local logged-in bar reference
        if loggedInBar?.id == bar.id {
            loggedInBar = updatedBar
        }
        
        // Send notification if status changed
        if oldStatus != newStatus {
            sendStatusChangeNotification(bar: updatedBar, oldStatus: oldStatus, newStatus: newStatus)
        }
        
        objectWillChange.send()
    }
    
    // MARK: - Schedule Monitoring (NEW)
    
    private func startScheduleMonitoring() {
        // Check for schedule-based status changes every minute
        scheduleMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkForScheduleBasedStatusChanges()
        }
    }
    
    private func checkForScheduleBasedStatusChanges() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let barsFollowingSchedule = self.bars.filter { $0.isFollowingSchedule }
            
            for var bar in barsFollowingSchedule {
                let currentStatus = bar.status
                let newScheduleStatus = bar.scheduleBasedStatus
                
                if currentStatus != newScheduleStatus {
                    print("📅 Schedule status change for \(bar.name): \(currentStatus.displayName) → \(newScheduleStatus.displayName)")
                    
                    // Update the bar's status in our local array
                    if let index = self.bars.firstIndex(where: { $0.id == bar.id }) {
                        self.bars[index].lastUpdated = Date()
                    }
                    
                    // Update in Firebase (just timestamp update since status is computed)
                    self.firebaseManager.updateBarWithAutoTransition(bar: bar)
                    
                    // Update logged-in bar if needed
                    if self.loggedInBar?.id == bar.id {
                        self.loggedInBar?.lastUpdated = Date()
                    }
                    
                    // Send notification for status change
                    self.sendStatusChangeNotification(bar: bar, oldStatus: currentStatus, newStatus: newScheduleStatus)
                }
            }
            
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Enhanced Notification System
    
    private func sendStatusChangeNotification(bar: Bar, oldStatus: BarStatus, newStatus: BarStatus) {
        // Only send notifications for Opening Soon and Closing Soon
        guard newStatus == .openingSoon || newStatus == .closingSoon else {
            print("🔕 Skipping notification for \(newStatus.displayName) - only notifying for Opening Soon/Closing Soon")
            return
        }
        
        // Send notification
        NotificationCenter.default.post(
            name: .barStatusChanged,
            object: nil,
            userInfo: [
                "barId": bar.id,
                "barName": bar.name,
                "newStatus": newStatus,
                "oldStatus": oldStatus,
                "isScheduleBased": bar.isFollowingSchedule
            ]
        )
        
        print("📢 Posted notification for \(bar.name): \(oldStatus.displayName) → \(newStatus.displayName)")
    }
    
    // MARK: - Auto-transition Monitoring (Enhanced)
    
    private func startAutoTransitionMonitoring() {
        // Check for manual auto-transitions every 10 seconds
        autoTransitionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkForAutoTransitions()
        }
    }
    
    private func checkForAutoTransitions() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let barsNeedingTransition = self.bars.filter { $0.shouldAutoTransition }
            
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
                    
                    // Send notification
                    self.sendStatusChangeNotification(bar: bar, oldStatus: oldStatus, newStatus: bar.status)
                    
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    // MARK: - UI Update Timer
    
    private func startUIUpdateTimer() {
        // Update UI every second for real-time countdown
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Firebase Integration (Updated)
    
    private func setupFirebaseConnection() {
        firebaseManager.$bars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bars in
                self?.bars = bars
                self?.syncFavoritesForAllBars()
            }
            .store(in: &cancellables)
        
        firebaseManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        setupBiometricAuth()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func syncFavoritesForAllBars() {
        let barIds = bars.map { $0.id }
        userPreferencesManager.syncAllFavoriteStatuses(for: barIds)
    }
    
    // MARK: - Notification Manager Integration
    
    func setNotificationManager(_ manager: NotificationManager) {
        self.notificationManager = manager
    }
    
    // MARK: - Existing methods (mostly unchanged)
    
    private func setupBiometricAuth() {
        if biometricAuth.savedBarID != nil {
            // Auto-login will be handled by the UI
        }
    }
    
    func createNewBar(_ bar: Bar, enableFaceID: Bool, completion: @escaping (Bool, String) -> Void) {
        if bars.contains(where: { $0.name.lowercased() == bar.name.lowercased() }) {
            completion(false, "A bar with this name already exists")
            return
        }
        
        firebaseManager.createBar(bar) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    if enableFaceID {
                        self?.biometricAuth.saveCredentials(barID: bar.id, barName: bar.name)
                        self?.loggedInBar = bar
                        self?.isOwnerMode = true
                    }
                    completion(true, "Bar created successfully! 🎉")
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
                        self?.fullLogout()
                    }
                    completion(true, "Bar deleted successfully")
                } else {
                    completion(false, message)
                }
            }
        }
    }
    
    // MARK: - Authentication (unchanged)
    
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
    
    // MARK: - Legacy Status Operations (Deprecated but kept for compatibility)
    
    func updateBarStatus(_ bar: Bar, newStatus: BarStatus) {
        // Redirect to new manual status method
        setManualBarStatus(bar, newStatus: newStatus)
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
    
    // MARK: - Enhanced Favorites System
    
    func toggleFavorite(barId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        userPreferencesManager.toggleFavorite(barId: barId) { [weak self] isNowFavorited in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
            
            completion(isNowFavorited)
            print("🔄 Favorite toggle completed for \(barId): \(isNowFavorited)")
            
            // Send test notification if favorited for the first time
            if isNowFavorited {
                self?.sendTestNotificationForNewFavorite(barId: barId)
            }
        }
    }
    
    private func sendTestNotificationForNewFavorite(barId: String) {
        guard let bar = bars.first(where: { $0.id == barId }),
              let notificationManager = notificationManager else { return }
        
        // Send a welcome notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            notificationManager.scheduleBarStatusNotification(
                barName: bar.name,
                newStatus: .openingSoon  // Test with Opening Soon
            )
        }
    }
    
    func getFavoriteCount(for barId: String) -> Int {
        return firebaseManager.getFavoriteCount(for: barId)
    }
    
    func isFavorite(barId: String) -> Bool {
        return userPreferencesManager.isFavorite(barId: barId)
    }
    
    // MARK: - Other existing methods (unchanged)
    
    func getBasicAnalytics(for barId: String, completion: @escaping ([String: Any]) -> Void) {
        firebaseManager.getBasicAnalytics(for: barId, completion: completion)
    }
    
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarDescription(barId: bar.id, newDescription: newDescription)
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.description = newDescription
            loggedInBar?.lastUpdated = Date()
        }
    }
    
    func updateBarOperatingHours(_ bar: Bar, newHours: OperatingHours) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarOperatingHours(barId: bar.id, operatingHours: newHours)
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.operatingHours = newHours
            loggedInBar?.lastUpdated = Date()
        }
    }
    
    func updateBarPassword(_ bar: Bar, newPassword: String) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarPassword(barId: bar.id, newPassword: newPassword)
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.password = newPassword
            loggedInBar?.lastUpdated = Date()
        }
    }
    
    func updateBarSocialLinks(_ bar: Bar, newSocialLinks: SocialLinks) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarSocialLinks(barId: bar.id, socialLinks: newSocialLinks)
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.socialLinks = newSocialLinks
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
    
    func debugFavorites() {
        userPreferencesManager.debugPrintStatus()
        print("📊 Firebase favorite counts: \(firebaseManager.favoriteCounts)")
    }
}
