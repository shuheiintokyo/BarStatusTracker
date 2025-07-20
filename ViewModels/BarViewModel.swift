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
    
    // Enhanced timers for schedule and auto-transition monitoring
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
        
        // Update local bars array
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index] = updatedBar
        }
        
        // Update local logged-in bar reference
        if loggedInBar?.id == bar.id {
            loggedInBar = updatedBar
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
        
        // Update local bars array
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index] = updatedBar
        }
        
        // Update local logged-in bar reference
        if loggedInBar?.id == bar.id {
            loggedInBar = updatedBar
        }
        
        objectWillChange.send()
    }
    
    // MARK: - Schedule Monitoring (Enhanced)
    
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
            var hasChanges = false
            
            for var bar in barsFollowingSchedule {
                let currentStatus = bar.status
                let newScheduleStatus = bar.scheduleBasedStatus
                
                if currentStatus != newScheduleStatus {
                    print("📅 Schedule status change for \(bar.name): \(currentStatus.displayName) → \(newScheduleStatus.displayName)")
                    
                    // Update the bar's timestamp in our local array
                    if let index = self.bars.firstIndex(where: { $0.id == bar.id }) {
                        self.bars[index].lastUpdated = Date()
                        hasChanges = true
                    }
                    
                    // Update in Firebase (just timestamp update since status is computed)
                    var timestampBar = bar
                    timestampBar.lastUpdated = Date()
                    self.firebaseManager.updateBarWithAutoTransition(bar: timestampBar)
                    
                    // Update logged-in bar if needed
                    if self.loggedInBar?.id == bar.id {
                        self.loggedInBar?.lastUpdated = Date()
                    }
                }
            }
            
            if hasChanges {
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Schedule Enforcement
    
    private func ensureBarsFollowScheduleOnClosedDays() {
        let today = getCurrentWeekDay()
        var hasChanges = false
        
        for var bar in bars {
            let todayHours = bar.operatingHours.getDayHours(for: today)
            
            // If today is a day the bar should be closed according to schedule
            if !todayHours.isOpen {
                // And the bar is showing as open due to manual override
                if bar.status != .closed && !bar.isFollowingSchedule {
                    print("📅 \(bar.name) should be closed on \(today.displayName)s - switching to follow schedule")
                    
                    // Force the bar to follow schedule
                    setBarToFollowSchedule(bar)
                    hasChanges = true
                }
            }
        }
        
        if hasChanges {
            objectWillChange.send()
        }
    }
    
    private func getCurrentWeekDay() -> WeekDay {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        switch weekday {
        case 1: return WeekDay.sunday
        case 2: return WeekDay.monday
        case 3: return WeekDay.tuesday
        case 4: return WeekDay.wednesday
        case 5: return WeekDay.thursday
        case 6: return WeekDay.friday
        case 7: return WeekDay.saturday
        default: return WeekDay.monday
        }
    }
    
    // MARK: - Auto-transition Monitoring
    
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
                    
                    // Update local bars array
                    if let index = self.bars.firstIndex(where: { $0.id == bar.id }) {
                        self.bars[index] = bar
                    }
                    
                    // Update local logged-in bar reference if needed
                    if self.loggedInBar?.id == bar.id {
                        self.loggedInBar = bar
                    }
                    
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
    
    // MARK: - Firebase Integration
    
    private func setupFirebaseConnection() {
        firebaseManager.$bars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bars in
                self?.bars = bars
                
                // Force any closed bars on days they shouldn't be open to follow schedule
                self?.ensureBarsFollowScheduleOnClosedDays()
            }
            .store(in: &cancellables)
        
        firebaseManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        setupBiometricAuth()
    }
    
    // MARK: - Authentication Methods
    
    private func setupBiometricAuth() {
        // Just check if we have saved credentials, don't auto-login
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
    
    // MARK: - Bar Management
    
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
    
    // MARK: - Bar Property Updates
    
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarDescription(barId: bar.id, newDescription: newDescription)
        
        // Update local arrays
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].description = newDescription
            bars[index].lastUpdated = Date()
        }
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.description = newDescription
            loggedInBar?.lastUpdated = Date()
        }
        
        objectWillChange.send()
    }
    
    func updateBarOperatingHours(_ bar: Bar, newHours: OperatingHours) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarOperatingHours(barId: bar.id, operatingHours: newHours)
        
        // Update local arrays
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].operatingHours = newHours
            bars[index].lastUpdated = Date()
        }
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.operatingHours = newHours
            loggedInBar?.lastUpdated = Date()
        }
        
        objectWillChange.send()
    }
    
    func updateBarPassword(_ bar: Bar, newPassword: String) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarPassword(barId: bar.id, newPassword: newPassword)
        
        // Update local arrays
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].password = newPassword
            bars[index].lastUpdated = Date()
        }
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.password = newPassword
            loggedInBar?.lastUpdated = Date()
        }
        
        objectWillChange.send()
    }
    
    func updateBarSocialLinks(_ bar: Bar, newSocialLinks: SocialLinks) {
        guard canEdit(bar: bar) else { return }
        
        firebaseManager.updateBarSocialLinks(barId: bar.id, socialLinks: newSocialLinks)
        
        // Update local arrays
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].socialLinks = newSocialLinks
            bars[index].lastUpdated = Date()
        }
        
        if loggedInBar?.id == bar.id {
            loggedInBar?.socialLinks = newSocialLinks
            loggedInBar?.lastUpdated = Date()
        }
        
        objectWillChange.send()
    }
    
    // MARK: - Auto-transition Management
    
    func cancelAutoTransition(for bar: Bar) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.cancelAutoTransition()
        
        firebaseManager.updateBarWithAutoTransition(bar: updatedBar)
        
        // Update local arrays
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index] = updatedBar
        }
        
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
    
    // MARK: - Data Access Methods
    
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
    
    // MARK: - Public Biometric Access Methods

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
    
    // MARK: - Legacy Support
    
    func updateBarStatus(_ bar: Bar, newStatus: BarStatus) {
        setManualBarStatus(bar, newStatus: newStatus)
    }
    
    // MARK: - Force Refresh Method
    
    func forceRefreshAllData() {
        print("🔄 Force refreshing all data...")
        
        // Refresh Firebase data
        firebaseManager.fetchBars()
        
        // Check for schedule changes
        checkForScheduleBasedStatusChanges()
        
        // Ensure schedule compliance
        ensureBarsFollowScheduleOnClosedDays()
        
        // Update UI
        objectWillChange.send()
    }
}
