import SwiftUI
import Combine

// MARK: - Simplified BarViewModel
class BarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var selectedBar: Bar?
    @Published var showingDetail = false
    @Published var loggedInBar: Bar? = nil
    @Published var isOwnerMode = false
    
    // MARK: - Dependencies
    private let dataService: BarDataService
    private let authService: AuthenticationService
    private let scheduleService: ScheduleService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: BarDataService = BarDataService(),
         authService: AuthenticationService = AuthenticationService(),
         scheduleService: ScheduleService = ScheduleService()) {
        self.dataService = dataService
        self.authService = authService
        self.scheduleService = scheduleService
        
        setupBindings()
        startPeriodicUpdates()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind data service to local state
        dataService.$bars
            .receive(on: DispatchQueue.main)
            .assign(to: &$bars)
        
        dataService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        // Update logged in bar when bars change
        dataService.$bars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bars in
                self?.updateLoggedInBarReference(from: bars)
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpdates() {
        // Update schedule-based statuses every minute
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshScheduleBasedStatuses()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Bar Management
    func createBar(_ bar: Bar, enableBiometrics: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        dataService.createBar(bar) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if enableBiometrics {
                        self?.authService.saveBiometricCredentials(barID: bar.id, barName: bar.name)
                        self?.loggedInBar = bar
                        self?.isOwnerMode = true
                    }
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func deleteBar(_ bar: Bar, completion: @escaping (Result<Void, Error>) -> Void) {
        guard canEdit(bar: bar) else {
            completion(.failure(BarError.unauthorized))
            return
        }
        
        dataService.deleteBar(barId: bar.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if self?.loggedInBar?.id == bar.id {
                        self?.logout()
                    }
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Status Management
    func setManualStatus(for bar: Bar, status: BarStatus) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.setManualStatus(status)
        
        updateBar(updatedBar)
    }
    
    func setBarToFollowSchedule(_ bar: Bar) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.followSchedule()
        
        updateBar(updatedBar)
    }
    
    func updateBarSchedule(_ bar: Bar, schedule: WeeklySchedule) {
        guard canEdit(bar: bar) else { return }
        
        var updatedBar = bar
        updatedBar.updateSchedule(schedule)
        
        updateBar(updatedBar)
    }
    
    // MARK: - Authentication
    func authenticateBar(username: String, password: String) -> Bool {
        let isValid = bars.contains {
            $0.username.lowercased() == username.lowercased() && $0.password == password
        }
        
        if isValid, let bar = bars.first(where: {
            $0.username.lowercased() == username.lowercased() && $0.password == password
        }) {
            loggedInBar = bar
            isOwnerMode = true
            authService.saveBiometricCredentials(barID: bar.id, barName: bar.name)
        }
        
        return isValid
    }
    
    func authenticateWithBiometrics(completion: @escaping (Result<Void, Error>) -> Void) {
        authService.authenticateWithBiometrics { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let barID):
                    if let bar = self?.bars.first(where: { $0.id == barID }) {
                        self?.loggedInBar = bar
                        self?.isOwnerMode = true
                        completion(.success(()))
                    } else {
                        completion(.failure(AuthError.barNotFound))
                    }
                case .failure(let error):
                    completion(.failure(error))
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
        authService.clearBiometricCredentials()
    }
    
    // MARK: - Helper Methods
    func canEdit(bar: Bar) -> Bool {
        return loggedInBar?.id == bar.id
    }
    
    var canUseBiometricAuth: Bool {
        return authService.isBiometricAuthAvailable
    }
    
    var biometricAuthInfo: (iconName: String, displayName: String) {
        return authService.biometricInfo
    }
    
    // MARK: - Data Access
    func getAllBars() -> [Bar] {
        return bars
    }
    
    func getOwnerBars() -> [Bar] {
        guard let loggedInBar = loggedInBar else { return [] }
        return bars.filter { $0.id == loggedInBar.id }
    }
    
    func getBarsOpenNow() -> [Bar] {
        return bars.filter { $0.status == .open || $0.status == .openingSoon }
    }
    
    func getBarsOpenToday() -> [Bar] {
        return bars.filter { $0.isOpenToday }
    }
    
    // MARK: - Private Methods
    private func updateBar(_ bar: Bar) {
        // Update local state immediately for responsive UI
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index] = bar
        }
        
        if loggedInBar?.id == bar.id {
            loggedInBar = bar
        }
        
        // Persist to backend
        dataService.updateBar(bar)
    }
    
    private func updateLoggedInBarReference(from bars: [Bar]) {
        guard let loggedInBarId = loggedInBar?.id else { return }
        loggedInBar = bars.first { $0.id == loggedInBarId }
    }
    
    private func refreshScheduleBasedStatuses() {
        // This will trigger recalculation of schedule-based statuses
        objectWillChange.send()
    }
}

// MARK: - Error Types
enum BarError: Error, LocalizedError {
    case unauthorized
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .notFound:
            return "Bar not found"
        case .invalidData:
            return "Invalid bar data"
        }
    }
}

enum AuthError: Error, LocalizedError {
    case barNotFound
    case biometricNotAvailable
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .barNotFound:
            return "Saved bar no longer exists"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
