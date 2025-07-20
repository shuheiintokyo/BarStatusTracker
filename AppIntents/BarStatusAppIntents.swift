import AppIntents
import Foundation

// MARK: - Bar Status App Intents (Simplified)

@available(iOS 16.0, *)
struct SetBarStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Bar Status"
    static var description = IntentDescription("Update your bar's status quickly using Siri")
    
    @Parameter(title: "Status")
    var status: BarStatusEntity
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Get the current logged-in bar (this would be enhanced with proper user context)
        let barViewModel = BarViewModel()
        
        guard let loggedInBar = barViewModel.loggedInBar else {
            throw AppIntentError.barNotFound
        }
        
        // Convert entity to BarStatus
        let newStatus = status.toBarStatus()
        
        // Update the status
        barViewModel.updateBarStatus(loggedInBar, newStatus: newStatus)
        
        let message = "Set \(loggedInBar.name) status to \(newStatus.displayName)"
        
        return .result(dialog: IntentDialog(message))
    }
}

@available(iOS 16.0, *)
struct CheckBarStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Bar Status"
    static var description = IntentDescription("Check if a bar is currently open and see its current status")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        guard let bar = bars.first(where: { $0.name.lowercased().contains(barName.lowercased()) }) else {
            throw AppIntentError.barNotFound
        }
        
        var message = "\(bar.name) is currently \(bar.status.displayName)"
        
        // Add timer info if applicable
        if bar.isAutoTransitionActive, let pendingStatus = bar.pendingStatus {
            message += " and will change to \(pendingStatus.displayName)"
            
            if let timeRemaining = barViewModel.getTimeRemainingText(for: bar) {
                message += " in \(timeRemaining)"
            }
        }
        
        // Add today's regular hours if available
        if bar.isOpenToday {
            message += ". Regular hours today: \(bar.todaysHours.displayText)"
        } else {
            message += ". Normally closed today"
        }
        
        return .result(dialog: IntentDialog(message))
    }
}

@available(iOS 16.0, *)
struct GetOpenBarsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Open Bars"
    static var description = IntentDescription("Get a list of currently open bars")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        let openBars = bars.filter { $0.status == .open || $0.status == .openingSoon }
        
        if openBars.isEmpty {
            return .result(dialog: IntentDialog("No bars are currently open"))
        }
        
        let barNames = openBars.map { bar in
            return "\(bar.name) - \(bar.status.displayName)"
        }
        
        let message = "Open bars: " + barNames.joined(separator: ", ")
        
        return .result(dialog: IntentDialog(message))
    }
}

@available(iOS 16.0, *)
struct CheckBarHoursIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Bar Hours"
    static var description = IntentDescription("Check a bar's regular operating hours")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        guard let bar = bars.first(where: { $0.name.lowercased().contains(barName.lowercased()) }) else {
            throw AppIntentError.barNotFound
        }
        
        // Get today's hours
        let todayMessage: String
        if bar.isOpenToday {
            todayMessage = "Today: \(bar.todaysHours.displayText)"
        } else {
            todayMessage = "Closed today"
        }
        
        // Get this week's schedule
        let openDays = WeekDay.allCases.filter { bar.operatingHours.getDayHours(for: $0).isOpen }
        
        let weekMessage: String
        if openDays.isEmpty {
            weekMessage = "No regular hours set"
        } else {
            let dayNames = openDays.map { $0.shortName }.joined(separator: ", ")
            weekMessage = "Usually open: \(dayNames)"
        }
        
        let message = "\(bar.name) - \(todayMessage). \(weekMessage)"
        
        return .result(dialog: IntentDialog(message))
    }
}

@available(iOS 16.0, *)
struct CreateNewBarIntent: AppIntent {
    static var title: LocalizedStringResource = "Create New Bar"
    static var description = IntentDescription("Create a new bar profile in the app")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @Parameter(title: "Address")
    var address: String
    
    @Parameter(title: "4-Digit Password")
    var password: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        
        // Validate password
        guard password.count == 4 else {
            throw AppIntentError.invalidPassword
        }
        
        // Check if bar name already exists
        if barViewModel.getAllBars().contains(where: { $0.name.lowercased() == barName.lowercased() }) {
            throw AppIntentError.barAlreadyExists
        }
        
        // Create new bar with default location (user would set specific location in app)
        let newBar = Bar(
            name: barName,
            latitude: 35.6762, // Default to Tokyo
            longitude: 139.6503,
            address: address,
            status: .closed,
            description: "Created via Siri",
            password: password
        )
        
        // Create bar using Firebase
        return await withCheckedContinuation { continuation in
            barViewModel.createNewBar(newBar, enableFaceID: false) { success, message in
                DispatchQueue.main.async {
                    if success {
                        continuation.resume(returning: .result(dialog: IntentDialog("Successfully created \(barName)! You can now log in and manage your bar in the app.")))
                    } else {
                        continuation.resume(returning: .result(dialog: IntentDialog("Failed to create bar: \(message)")))
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct GetAllBarsIntent: AppIntent {
    static var title: LocalizedStringResource = "List All Bars"
    static var description = IntentDescription("Get a list of all available bars and their current status")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        if bars.isEmpty {
            return .result(dialog: IntentDialog("No bars are available in the app yet"))
        }
        
        let barList = bars.prefix(10).map { bar in
            let locationInfo = bar.location?.city ?? ""
            let location = locationInfo.isEmpty ? "" : " in \(locationInfo)"
            return "\(bar.name)\(location) - \(bar.status.displayName)"
        }
        
        var message = "Available bars: " + barList.joined(separator: ", ")
        
        if bars.count > 10 {
            message += " and \(bars.count - 10) more"
        }
        
        return .result(dialog: IntentDialog(message))
    }
}

// MARK: - Supporting Types

@available(iOS 16.0, *)
struct BarStatusEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Bar Status"
    static var defaultQuery = BarStatusQuery()
    
    var id: String
    var displayName: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }
    
    func toBarStatus() -> BarStatus {
        switch id {
        case "opening_soon": return .openingSoon
        case "open": return .open
        case "closing_soon": return .closingSoon
        case "closed": return .closed
        default: return .closed
        }
    }
}

@available(iOS 16.0, *)
struct BarStatusQuery: EntityQuery {
    func entities(for identifiers: [BarStatusEntity.ID]) async throws -> [BarStatusEntity] {
        return allStatuses.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [BarStatusEntity] {
        return allStatuses
    }
    
    private var allStatuses: [BarStatusEntity] {
        return [
            BarStatusEntity(id: "opening_soon", displayName: "Opening Soon"),
            BarStatusEntity(id: "open", displayName: "Open"),
            BarStatusEntity(id: "closing_soon", displayName: "Closing Soon"),
            BarStatusEntity(id: "closed", displayName: "Closed")
        ]
    }
}

// MARK: - Error Types

enum AppIntentError: Error, LocalizedError {
    case barNotFound
    case notLoggedIn
    case invalidStatus
    case invalidPassword
    case barAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .barNotFound:
            return "Bar not found. Please check the name and try again."
        case .notLoggedIn:
            return "You need to be logged in as a bar owner to change status."
        case .invalidStatus:
            return "Invalid status provided."
        case .invalidPassword:
            return "Password must be exactly 4 digits."
        case .barAlreadyExists:
            return "A bar with this name already exists."
        }
    }
}

// MARK: - Shortcuts Provider (Simplified)

@available(iOS 16.0, *)
struct BarStatusAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: SetBarStatusIntent(),
                phrases: [
                    "Set my bar to \(.applicationName)",
                    "Update my bar status in \(.applicationName)",
                    "Change my bar to \(.applicationName)"
                ],
                shortTitle: "Set Bar Status",
                systemImageName: "building.2"
            ),
            AppShortcut(
                intent: CheckBarStatusIntent(),
                phrases: [
                    "Check if \(.applicationName) is open",
                    "Is \(.applicationName) open",
                    "What's the status of \(.applicationName)"
                ],
                shortTitle: "Check Bar Status",
                systemImageName: "questionmark.circle"
            ),
            AppShortcut(
                intent: CheckBarHoursIntent(),
                phrases: [
                    "What are \(.applicationName) hours",
                    "When is \(.applicationName) open",
                    "Check \(.applicationName) operating hours"
                ],
                shortTitle: "Check Bar Hours",
                systemImageName: "clock"
            ),
            AppShortcut(
                intent: GetOpenBarsIntent(),
                phrases: [
                    "Show me open bars in \(.applicationName)",
                    "What bars are open in \(.applicationName)",
                    "List open bars in \(.applicationName)"
                ],
                shortTitle: "Show Open Bars",
                systemImageName: "list.bullet"
            ),
            AppShortcut(
                intent: GetAllBarsIntent(),
                phrases: [
                    "List all bars in \(.applicationName)",
                    "Show me all bars in \(.applicationName)",
                    "What bars are available in \(.applicationName)"
                ],
                shortTitle: "List All Bars",
                systemImageName: "building.2.crop.circle"
            ),
            AppShortcut(
                intent: CreateNewBarIntent(),
                phrases: [
                    "Create a new bar in \(.applicationName)",
                    "Add my bar to \(.applicationName)",
                    "Register my bar in \(.applicationName)"
                ],
                shortTitle: "Create New Bar",
                systemImageName: "plus.circle"
            )
        ]
    }
}
