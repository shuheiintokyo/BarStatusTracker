import AppIntents
import Foundation

// MARK: - Fixed Bar Status App Intents

@available(iOS 16.0, *)
struct SetBarStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Bar Status"
    static var description = IntentDescription("Update your bar's status quickly using Siri")
    
    @Parameter(title: "Status")
    var status: BarStatusEntity
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        
        guard let loggedInBar = barViewModel.loggedInBar else {
            throw AppIntentError.barNotFound
        }
        
        // Convert entity to BarStatus
        let newStatus = status.toBarStatus()
        
        // Update the status (this will set a manual override)
        barViewModel.setManualBarStatus(loggedInBar, newStatus: newStatus)
        
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
        
        // Add today's schedule if available
        if let todaysSchedule = bar.todaysSchedule {
            if todaysSchedule.isOpen {
                message += ". Today's hours: \(todaysSchedule.displayText)"
            } else {
                message += ". Closed today"
            }
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

// MARK: - NEW: Check Today's Schedule Intent
@available(iOS 16.0, *)
struct CheckTodaysScheduleIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Today's Schedule"
    static var description = IntentDescription("Check your bar's schedule for today")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        
        guard let loggedInBar = barViewModel.loggedInBar else {
            throw AppIntentError.barNotFound
        }
        
        guard let todaysSchedule = loggedInBar.todaysSchedule else {
            return .result(dialog: IntentDialog("No schedule set for today"))
        }
        
        let dayName = todaysSchedule.dayName
        let message: String
        
        if todaysSchedule.isOpen {
            message = "Today (\(dayName)), \(loggedInBar.name) is scheduled to be open from \(todaysSchedule.openTime) to \(todaysSchedule.closeTime)"
        } else {
            message = "Today (\(dayName)), \(loggedInBar.name) is scheduled to be closed"
        }
        
        return .result(dialog: IntentDialog(message))
    }
}

// MARK: - NEW: Check This Week's Schedule Intent
@available(iOS 16.0, *)
struct CheckWeekScheduleIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Week Schedule"
    static var description = IntentDescription("Check your bar's schedule for this week")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        
        guard let loggedInBar = barViewModel.loggedInBar else {
            throw AppIntentError.barNotFound
        }
        
        let weekSchedule = loggedInBar.weeklySchedule
        let openDays = weekSchedule.schedules.filter { $0.isOpen }
        
        if openDays.isEmpty {
            return .result(dialog: IntentDialog("\(loggedInBar.name) is closed all week"))
        }
        
        let daysList = openDays.map { schedule in
            "\(schedule.shortDayName) \(schedule.displayDate)"
        }.joined(separator: ", ")
        
        let message = "\(loggedInBar.name) is open \(openDays.count) days this week: \(daysList)"
        
        return .result(dialog: IntentDialog(message))
    }
}

// MARK: - NEW: Update Today's Hours Intent
@available(iOS 16.0, *)
struct UpdateTodaysHoursIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Today's Hours"
    static var description = IntentDescription("Update your bar's hours for today")
    
    @Parameter(title: "Open Time")
    var openTime: String?
    
    @Parameter(title: "Close Time")
    var closeTime: String?
    
    @Parameter(title: "Is Open Today")
    var isOpen: Bool
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        
        guard let loggedInBar = barViewModel.loggedInBar else {
            throw AppIntentError.barNotFound
        }
        
        var updatedSchedule = loggedInBar.weeklySchedule
        
        // Find today's schedule and update it
        guard let todayIndex = updatedSchedule.schedules.firstIndex(where: { $0.isToday }) else {
            throw AppIntentError.invalidDay
        }
        
        // Update today's schedule
        updatedSchedule.schedules[todayIndex].isOpen = isOpen
        
        if let openTime = openTime {
            updatedSchedule.schedules[todayIndex].openTime = openTime
        }
        
        if let closeTime = closeTime {
            updatedSchedule.schedules[todayIndex].closeTime = closeTime
        }
        
        // Update the bar's schedule
        barViewModel.updateBarSchedule(loggedInBar, newSchedule: updatedSchedule)
        
        let scheduleText = isOpen ?
            "open from \(updatedSchedule.schedules[todayIndex].openTime) to \(updatedSchedule.schedules[todayIndex].closeTime)" :
            "closed"
        
        let message = "Updated \(loggedInBar.name) to be \(scheduleText) today"
        
        return .result(dialog: IntentDialog(message))
    }
}

// MARK: - NEW: Return to Schedule Intent
@available(iOS 16.0, *)
struct ReturnToScheduleIntent: AppIntent {
    static var title: LocalizedStringResource = "Follow Schedule"
    static var description = IntentDescription("Return your bar to following its regular schedule")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        
        guard let loggedInBar = barViewModel.loggedInBar else {
            throw AppIntentError.barNotFound
        }
        
        let oldStatus = loggedInBar.status
        barViewModel.setBarToFollowSchedule(loggedInBar)
        
        // Get the updated bar to see new status
        let updatedBar = barViewModel.bars.first { $0.id == loggedInBar.id } ?? loggedInBar
        let newStatus = updatedBar.status
        
        let message = "\(loggedInBar.name) is now following its schedule. Status changed from \(oldStatus.displayName) to \(newStatus.displayName)"
        
        return .result(dialog: IntentDialog(message))
    }
}

// MARK: - UPDATED: Check Bar Hours Intent (for 7-day schedule)
@available(iOS 16.0, *)
struct CheckBarHoursIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Bar Hours"
    static var description = IntentDescription("Check a bar's schedule for the week")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        guard let bar = bars.first(where: { $0.name.lowercased().contains(barName.lowercased()) }) else {
            throw AppIntentError.barNotFound
        }
        
        // Get today's schedule
        let todayMessage: String
        if let todaysSchedule = bar.todaysSchedule {
            if todaysSchedule.isOpen {
                todayMessage = "Today: \(todaysSchedule.displayText)"
            } else {
                todayMessage = "Closed today"
            }
        } else {
            todayMessage = "No schedule for today"
        }
        
        // Get this week's open days
        let openDays = bar.weeklySchedule.schedules.filter { $0.isOpen }
        
        let weekMessage: String
        if openDays.isEmpty {
            weekMessage = "Closed all week"
        } else {
            let dayNames = openDays.map { "\($0.shortDayName) \($0.displayDate)" }.joined(separator: ", ")
            weekMessage = "Open \(openDays.count) days this week: \(dayNames)"
        }
        
        let message = "\(bar.name) - \(todayMessage). \(weekMessage)"
        
        return .result(dialog: IntentDialog(message))
    }
}

// MARK: - Create Bar Intent (Fixed)
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
        
        // Create new bar with default 7-day schedule
        let newBar = Bar(
            name: barName,
            address: address,
            description: "Created via Siri",
            username: barName,
            password: password
        )
        
        // Create bar using the fixed method
        return await withCheckedContinuation { continuation in
            barViewModel.createNewBar(newBar, enableFaceID: false) { success, message in
                DispatchQueue.main.async {
                    if success {
                        continuation.resume(returning: .result(dialog: IntentDialog("Successfully created \(barName)! You can now log in and set your 7-day schedule in the app.")))
                    } else {
                        continuation.resume(returning: .result(dialog: IntentDialog("Failed to create bar: \(message)")))
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types (unchanged)

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

// MARK: - Error Types (updated)

enum AppIntentError: Error, LocalizedError {
    case barNotFound
    case notLoggedIn
    case invalidStatus
    case invalidPassword
    case barAlreadyExists
    case invalidDay
    case scheduleNotFound
    
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
        case .invalidDay:
            return "Invalid day specified."
        case .scheduleNotFound:
            return "No schedule found for the specified day."
        }
    }
}

// MARK: - UPDATED: Shortcuts Provider (with new intents)

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
                intent: CheckTodaysScheduleIntent(),
                phrases: [
                    "What are my bar's hours today in \(.applicationName)",
                    "Check today's schedule in \(.applicationName)",
                    "Am I open today in \(.applicationName)"
                ],
                shortTitle: "Check Today's Schedule",
                systemImageName: "calendar.circle"
            ),
            AppShortcut(
                intent: CheckWeekScheduleIntent(),
                phrases: [
                    "What's my schedule this week in \(.applicationName)",
                    "Check this week's hours in \(.applicationName)",
                    "Show my weekly schedule in \(.applicationName)"
                ],
                shortTitle: "Check Week Schedule",
                systemImageName: "calendar.badge.clock"
            ),
            AppShortcut(
                intent: UpdateTodaysHoursIntent(),
                phrases: [
                    "Update today's hours in \(.applicationName)",
                    "Change my hours for today in \(.applicationName)",
                    "Set today's schedule in \(.applicationName)"
                ],
                shortTitle: "Update Today's Hours",
                systemImageName: "clock.badge.checkmark"
            ),
            AppShortcut(
                intent: ReturnToScheduleIntent(),
                phrases: [
                    "Follow my schedule in \(.applicationName)",
                    "Return to schedule in \(.applicationName)",
                    "Stop manual override in \(.applicationName)"
                ],
                shortTitle: "Follow Schedule",
                systemImageName: "calendar.badge.checkmark"
            ),
            AppShortcut(
                intent: CheckBarHoursIntent(),
                phrases: [
                    "What are \(.applicationName) hours",
                    "When is \(.applicationName) open",
                    "Check \(.applicationName) schedule"
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
