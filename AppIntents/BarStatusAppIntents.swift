import AppIntents
import Foundation

// MARK: - Bar Status App Intents

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
    static var description = IntentDescription("Check if a bar is currently open and see how popular it is")
    
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
        
        // Add popularity info from Firebase
        let favoriteCount = barViewModel.getFavoriteCount(for: bar.id)
        if favoriteCount > 0 {
            message += ". This bar has \(favoriteCount) \(favoriteCount == 1 ? "favorite" : "favorites")"
        }
        
        return .result(dialog: IntentDialog(message))
    }
}

@available(iOS 16.0, *)
struct GetOpenBarsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Open Bars"
    static var description = IntentDescription("Get a list of currently open bars with their popularity")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        let openBars = bars.filter { $0.status == .open || $0.status == .openingSoon }
        
        if openBars.isEmpty {
            return .result(dialog: IntentDialog("No bars are currently open"))
        }
        
        let barNames = openBars.map { bar in
            let favoriteCount = barViewModel.getFavoriteCount(for: bar.id)
            let popularity = favoriteCount > 0 ? " (\(favoriteCount) ❤️)" : ""
            return "\(bar.name) - \(bar.status.displayName)\(popularity)"
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
struct AddBarToFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Bar to Favorites"
    static var description = IntentDescription("Add a bar to your favorites list and get notifications")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        guard let bar = bars.first(where: { $0.name.lowercased().contains(barName.lowercased()) }) else {
            throw AppIntentError.barNotFound
        }
        
        if barViewModel.isFavorite(barId: bar.id) {
            return .result(dialog: IntentDialog("\(bar.name) is already in your favorites"))
        }
        
        // Use the new Firebase-integrated toggle favorite
        return await withCheckedContinuation { continuation in
            barViewModel.toggleFavorite(barId: bar.id)
            
            // Give it a moment to complete the Firebase operation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let favoriteCount = barViewModel.getFavoriteCount(for: bar.id)
                let message = "Added \(bar.name) to your favorites. You'll now receive notifications when their status changes. This bar now has \(favoriteCount) \(favoriteCount == 1 ? "favorite" : "favorites")."
                
                continuation.resume(returning: .result(dialog: IntentDialog(message)))
            }
        }
    }
}

@available(iOS 16.0, *)
struct RemoveBarFromFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove Bar from Favorites"
    static var description = IntentDescription("Remove a bar from your favorites list")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        guard let bar = bars.first(where: { $0.name.lowercased().contains(barName.lowercased()) }) else {
            throw AppIntentError.barNotFound
        }
        
        if !barViewModel.isFavorite(barId: bar.id) {
            return .result(dialog: IntentDialog("\(bar.name) is not in your favorites"))
        }
        
        // Use the new Firebase-integrated toggle favorite
        return await withCheckedContinuation { continuation in
            barViewModel.toggleFavorite(barId: bar.id)
            
            // Give it a moment to complete the Firebase operation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let message = "Removed \(bar.name) from your favorites. You'll no longer receive notifications about this bar."
                continuation.resume(returning: .result(dialog: IntentDialog(message)))
            }
        }
    }
}

@available(iOS 16.0, *)
struct GetBarPopularityIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Bar Popularity"
    static var description = IntentDescription("See how many people have favorited a specific bar")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        guard let bar = bars.first(where: { $0.name.lowercased().contains(barName.lowercased()) }) else {
            throw AppIntentError.barNotFound
        }
        
        let favoriteCount = barViewModel.getFavoriteCount(for: bar.id)
        
        let message: String
        if favoriteCount == 0 {
            message = "\(bar.name) doesn't have any favorites yet. Be the first to like it!"
        } else if favoriteCount == 1 {
            message = "\(bar.name) has 1 person who has favorited it"
        } else {
            message = "\(bar.name) has \(favoriteCount) people who have favorited it"
        }
        
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
    case favoriteError
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
        case .favoriteError:
            return "Unable to update favorites. Please try again."
        case .invalidPassword:
            return "Password must be exactly 4 digits."
        case .barAlreadyExists:
            return "A bar with this name already exists."
        }
    }
}

// MARK: - Shortcuts Provider

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
                intent: AddBarToFavoritesIntent(),
                phrases: [
                    "Add \(.applicationName) to favorites",
                    "Favorite \(.applicationName) bar",
                    "Follow \(.applicationName) in my bar app"
                ],
                shortTitle: "Add to Favorites",
                systemImageName: "heart"
            ),
            AppShortcut(
                intent: GetBarPopularityIntent(),
                phrases: [
                    "How popular is \(.applicationName)",
                    "Check \(.applicationName) popularity",
                    "How many people like \(.applicationName)"
                ],
                shortTitle: "Check Popularity",
                systemImageName: "heart.text.square"
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
