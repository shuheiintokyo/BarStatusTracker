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
    
    // Enhanced timers for schedule monitoring and status consistency
    private var scheduleMonitoringTimer: Timer?
    private var autoTransitionTimer: Timer?
    private var uiUpdateTimer: Timer?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupFirebaseConnection()
        startScheduleMonitoring()
        startAutoTransitionMonitoring()
        startUIUpdateTimer()
    }
    
    deinit {
        scheduleMonitoringTimer?.invalidate()
        autoTransitionTimer?.invalidate()
        uiUpdateTimer?.invalidate()
    }
    
    // MARK: - SIMPLIFIED STATUS MANAGEMENT (7-Day Schedule Based)
    
    /// Set manual status override (Owner only - for quick actions)
    func setManualBarStatus(_ bar: Bar, newStatus: BarStatus) {
        guard canEdit(bar: bar) else {
            print("❌ Unauthorized attempt to change bar status")
            return
        }
        
        var updatedBar = bar
        let oldStatus = bar.status
        
        // Use the new Bar model method for manual override
        updatedBar.setManualStatusOverride(newStatus)
        
        print("🔧 Owner manually set \(bar.name): \(oldStatus.displayName) → \(newStatus.displayName)")
        
        // Update in Firebase
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        
        // Update local state
        updateLocalBarState(updatedBar)
        
        objectWillChange.send()
    }
    
    /// Return bar to follow schedule (Owner only)
    func setBarToFollowSchedule(_ bar: Bar) {
        guard canEdit(bar: bar) else {
            print("❌ Unauthorized attempt to change bar schedule following")
            return
        }
        
        var updatedBar = bar
        let oldStatus = bar.status
        
        // Use the new Bar model method to return to schedule
        updatedBar.returnToSchedule()
        let newStatus = updatedBar.status
        
        print("📅 Owner set \(bar.name) to follow schedule: \(oldStatus.displayName) → \(newStatus.displayName)")
        
        // Update in Firebase
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        
        // Update local state
        updateLocalBarState(updatedBar)
        
        objectWillChange.send()
    }
    
    /// Update the 7-day schedule (Owner only) - MAIN CONTROL METHOD
    func updateBarSchedule(_ bar: Bar, newSchedule: WeeklySchedule) {
        guard canEdit(bar: bar) else {
            print("❌ Unauthorized attempt to update bar schedule")
            return
        }
        
        var updatedBar = bar
        let oldStatus = bar.status
        
        // Update the schedule
        updatedBar.updateWeeklySchedule(newSchedule)
        let newStatus = updatedBar.status
        
        print("📅 Owner updated \(bar.name) schedule: \(oldStatus.displayName) → \(newStatus.displayName)")
        
        // Update in Firebase
        firebaseManager.updateBarSchedule(barId: bar.id, weeklySchedule: newSchedule)
        
        // Update local state
        updateLocalBarState(updatedBar)
        
        objectWillChange.send()
    }
    
    // MARK: - SCHEDULE MONITORING (Updated for 7-Day System)
    
    private func startScheduleMonitoring() {
        // Check for schedule-based status changes every minute
        scheduleMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkForScheduleBasedStatusChanges()
        }
    }
    
    private func checkForScheduleBasedStatusChanges() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var hasChanges = false
            
            for var bar in self.bars {
                let oldComputedStatus = bar.status
                
                // Refresh timestamp and roll forward schedule if needed
                bar.refreshTimestamp()
                let newComputedStatus = bar.status
                
                if oldComputedStatus != newComputedStatus {
                    print("📅 Schedule-based status change for \(bar.name): \(oldComputedStatus.displayName) → \(newComputedStatus.displayName)")
                    
                    // Update the bar in our local array
                    if let index = self.bars.firstIndex(where: { $0.id == bar.id }) {
                        self.bars[index] = bar
                        hasChanges = true
                    }
                    
                    // Update in Firebase (timestamp and potentially rolled-forward schedule)
                    self.firebaseManager.updateBarWithAutoTransition(bar: bar)
                    
                    // Update logged-in bar if needed
                    if self.loggedInBar?.id == bar.id {
                        self.loggedInBar = bar
                    }
                }
            }
            
            if hasChanges {
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - SCHEDULE CONSISTENCY ENFORCEMENT
    
    /// Ensure all bars have up-to-date 7-day schedules (called on app start)
    private func enforceScheduleConsistency() {
        var hasChanges = false
        
        for var bar in bars {
            // Ensure schedule is rolled forward to current date
            let oldScheduleCount = bar.weeklySchedule.schedules.count
            bar.weeklySchedule.rollForwardIfNeeded()
            let newScheduleCount = bar.weeklySchedule.schedules.count
            
            if oldScheduleCount != newScheduleCount || bar.weeklySchedule.schedules.count != 7 {
                print("📅 \(bar.name) schedule updated: rolling forward or regenerating")
                
                if let index = bars.firstIndex(where: { $0.id == bar.id }) {
                    bars[index] = bar
                    hasChanges = true
                }
                
                // Update in Firebase with new schedule
                firebaseManager.updateBarSchedule(barId: bar.id, weeklySchedule: bar.weeklySchedule)
            }
            
            // Refresh timestamp for status consistency
            let oldStatus = bar.status
            bar.refreshTimestamp()
            let newStatus = bar.status
            
            if oldStatus != newStatus {
                if let index = bars.firstIndex(where: { $0.id == bar.id }) {
                    bars[index] = bar
                    hasChanges = true
                }
            }
        }
        
        if hasChanges {
            objectWillChange.send()
        }
    }
    
    // MARK: - AUTO-TRANSITION MONITORING (Keep existing)
    
    private func startAutoTransitionMonitoring() {
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
                    
                    // Update local state
                    self.updateLocalBarState(bar)
                    
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    // MARK: - UI UPDATE TIMER
    
    private func startUIUpdateTimer() {
        // Update UI every second for real-time countdown and status consistency
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    // MARK: - FIREBASE INTEGRATION (Updated)
    
    private func setupFirebaseConnection() {
        firebaseManager.$bars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bars in
                self?.bars = bars
                
                // Enforce schedule consistency on data load
                self?.enforceScheduleConsistency()
            }
            .store(in: &cancellables)
        
        firebaseManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        setupBiometricAuth()
    }
    
    // MARK: - LOCAL STATE UPDATE HELPER
    
    private func updateLocalBarState(_ updatedBar: Bar) {
        // Update local bars array
        if let index = bars.firstIndex(where: { $0.id == updatedBar.id }) {
            bars[index] = updatedBar
        }
        
        // Update local logged-in bar reference
        if loggedInBar?.id == updatedBar.id {
            loggedInBar = updatedBar
        }
    }
    
    // MARK: - AUTHENTICATION METHODS (Keep existing)
    
    private func setupBiometricAuth() {
        if biometricAuth.savedBarID != nil {
            print("ℹ️ Found saved biometric credentials")
        }
    }
    
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
    
    var canUseBiometricAuth: Bool {
        return biometricAuth.isAvailable
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
    
    // MARK: - BAR MANAGEMENT (Updated for 7-Day Schedule)
    
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
    
    // MARK: - BAR PROPERTY UPDATES (Updated for 7-Day Schedule)
    
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarDescription(barId: bar.id, newDescription: newDescription)
        
        var updatedBar = bar
        updatedBar.description = newDescription
        updatedBar.refreshTimestamp()
        updateLocalBarState(updatedBar)
        
        objectWillChange.send()
    }
    
    func updateBarPassword(_ bar: Bar, newPassword: String) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarPassword(barId: bar.id, newPassword: newPassword)
        
        var updatedBar = bar
        updatedBar.password = newPassword
        updatedBar.refreshTimestamp()
        updateLocalBarState(updatedBar)
        
        objectWillChange.send()
    }
    
    func updateBarSocialLinks(_ bar: Bar, newSocialLinks: SocialLinks) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarSocialLinks(barId: bar.id, socialLinks: newSocialLinks)
        
        var updatedBar = bar
        updatedBar.socialLinks = newSocialLinks
        updatedBar.refreshTimestamp()
        updateLocalBarState(updatedBar)
        
        objectWillChange.send()
    }
    
    // MARK: - AUTO-TRANSITION MANAGEMENT (Keep existing)
    
    func cancelAutoTransition(for bar: Bar) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.cancelAutoTransition()
        
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        updateLocalBarState(updatedBar)
        
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
    
    // MARK: - DATA ACCESS METHODS
    
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
    
    // MARK: - BIOMETRIC ACCESS METHODS (Keep existing)

    var savedBiometricBarID: String? {
        return biometricAuth.savedBarID
    }

    func isValidBiometricBar() -> Bool {
        guard let savedBarID = biometricAuth.savedBarID,
              !savedBarID.isEmpty else {
            return false
        }
        
        return bars.contains { $0.id == savedBarID }
    }

    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        guard biometricAuth.isAvailable else {
            completion(false, "Biometric authentication not properly set up")
            return
        }
        
        guard let savedBarID = biometricAuth.savedBarID else {
            completion(false, "No saved bar credentials found")
            return
        }
        
        biometricAuth.authenticateWithBiometrics { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false, "Internal error")
                    return
                }
                
                if success {
                    if let bar = self.bars.first(where: { $0.id == savedBarID }) {
                        self.loggedInBar = bar
                        self.isOwnerMode = true
                        completion(true, nil)
                        print("✅ Biometric authentication successful for: \(bar.name)")
                    } else {
                        print("❌ Saved bar no longer exists, clearing credentials")
                        self.biometricAuth.clearCredentials()
                        completion(false, "Your saved bar is no longer available. Please log in manually.")
                    }
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    // MARK: - LEGACY SUPPORT (For compatibility with existing code)
    
    func updateBarStatus(_ bar: Bar, newStatus: BarStatus) {
        setManualBarStatus(bar, newStatus: newStatus)
    }
    
    // DEPRECATED: Use updateBarSchedule instead
    func updateBarOperatingHours(_ bar: Bar, newHours: OperatingHours) {
        print("⚠️ Deprecated method called: updateBarOperatingHours. Use updateBarSchedule instead.")
        // For now, just update timestamp to trigger UI refresh
        var updatedBar = bar
        updatedBar.refreshTimestamp()
        updateLocalBarState(updatedBar)
        objectWillChange.send()
    }
    
    // MARK: - FORCE REFRESH METHOD
    
    func forceRefreshAllData() {
        print("🔄 Force refreshing all data...")
        
        // Refresh Firebase data
        firebaseManager.fetchBars()
        
        // Check for schedule changes and roll forward
        checkForScheduleBasedStatusChanges()
        
        // Ensure schedule consistency
        enforceScheduleConsistency()
        
        // Update UI
        objectWillChange.send()
    }
}

// MARK: - Schedule-Aware Helper Methods (Add these to the end of BarViewModel.swift)

extension BarViewModel {
    /// Get bars that are open today (based on schedule)
    func getBarsOpenToday() -> [Bar] {
        return getAllBars().filter { $0.isOpenToday }
    }
    
    /// Get bars that are currently open (status-based)
    func getCurrentlyOpenBars() -> [Bar] {
        return getAllBars().filter { $0.status == .open || $0.status == .openingSoon }
    }
    
    /// Get count of bars with manual overrides
    func getBarsWithManualOverrides() -> [Bar] {
        return getAllBars().filter { !$0.isFollowingSchedule }
    }
    
    /// Get bars that have conflicting status vs schedule
    func getBarsWithStatusConflicts() -> [Bar] {
        return getAllBars().filter { $0.isStatusConflictingWithSchedule }
    }
    
    /// Get bars grouped by status
    func getBarsGroupedByStatus() -> [BarStatus: [Bar]] {
        let allBars = getAllBars()
        var groupedBars: [BarStatus: [Bar]] = [:]
        
        for status in BarStatus.allCases {
            groupedBars[status] = allBars.filter { $0.status == status }
        }
        
        return groupedBars
    }
    
    /// Get summary statistics for dashboard/header display
    func getBarStatistics() -> BarStatistics {
        let allBars = getAllBars()
        return BarStatistics(
            totalBars: allBars.count,
            openNow: allBars.filter { $0.status == .open || $0.status == .openingSoon }.count,
            openToday: allBars.filter { $0.isOpenToday }.count,
            manualOverrides: allBars.filter { !$0.isFollowingSchedule }.count,
            autoTransitions: allBars.filter { $0.isAutoTransitionActive }.count,
            statusConflicts: allBars.filter { $0.isStatusConflictingWithSchedule }.count
        )
    }
    
    /// Get bars by location
    func getBarsByLocation() -> [String: [Bar]] {
        let allBars = getAllBars()
        var barsByLocation: [String: [Bar]] = [:]
        
        for bar in allBars {
            let locationKey = bar.location?.displayName ?? "Unknown Location"
            if barsByLocation[locationKey] == nil {
                barsByLocation[locationKey] = []
            }
            barsByLocation[locationKey]?.append(bar)
        }
        
        return barsByLocation
    }
}

// MARK: - Supporting Statistics Structure

struct BarStatistics {
    let totalBars: Int
    let openNow: Int
    let openToday: Int
    let manualOverrides: Int
    let autoTransitions: Int
    let statusConflicts: Int
    
    var openNowPercentage: Double {
        guard totalBars > 0 else { return 0 }
        return Double(openNow) / Double(totalBars) * 100
    }
    
    var openTodayPercentage: Double {
        guard totalBars > 0 else { return 0 }
        return Double(openToday) / Double(totalBars) * 100
    }
}
