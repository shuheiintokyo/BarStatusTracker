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
    static var description = IntentDescription("Check if a bar is currently open")
    
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
        
        let barNames = openBars.map { "\($0.name) (\($0.status.displayName))" }
        let message = "Open bars: " + barNames.joined(separator: ", ")
        
        return .result(dialog: IntentDialog(message))
    }
}

@available(iOS 16.0, *)
struct AddBarToFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Bar to Favorites"
    static var description = IntentDescription("Add a bar to your favorites list")
    
    @Parameter(title: "Bar Name")
    var barName: String
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let barViewModel = BarViewModel()
        let bars = barViewModel.getAllBars()
        
        guard let bar = bars.first(where: { $0.name.lowercased().contains(barName.lowercased()) }) else {
            throw AppIntentError.barNotFound
        }
        
        let userPreferences = barViewModel.userPreferences
        
        if userPreferences.isFavorite(barId: bar.id) {
            return .result(dialog: IntentDialog("\(bar.name) is already in your favorites"))
        }
        
        userPreferences.addFavorite(barId: bar.id)
        
        return .result(dialog: IntentDialog("Added \(bar.name) to your favorites. You'll now receive notifications when their status changes."))
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
    
    var errorDescription: String? {
        switch self {
        case .barNotFound:
            return "Bar not found. Please check the name and try again."
        case .notLoggedIn:
            return "You need to be logged in as a bar owner to change status."
        case .invalidStatus:
            return "Invalid status provided."
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
            )
        ]
    }
}
