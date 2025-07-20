import Foundation
import FirebaseFirestore

// MARK: - New 7-Day Rolling Schedule Models

struct DailySchedule: Codable, Identifiable {
    let id = UUID()
    let date: Date
    var isOpen: Bool = false
    var openTime: String = "18:00" // 6 PM default
    var closeTime: String = "06:00" // 6 AM next day default
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var displayText: String {
        if !isOpen {
            return "Closed"
        }
        return "\(openTime) - \(closeTime)"
    }
    
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "date": Timestamp(date: date),
            "isOpen": isOpen,
            "openTime": openTime,
            "closeTime": closeTime
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> DailySchedule? {
        guard let timestamp = dict["date"] as? Timestamp else { return nil }
        
        var schedule = DailySchedule(date: timestamp.dateValue())
        schedule.isOpen = dict["isOpen"] as? Bool ?? false
        schedule.openTime = dict["openTime"] as? String ?? "18:00"
        schedule.closeTime = dict["closeTime"] as? String ?? "06:00"
        return schedule
    }
}

struct WeeklySchedule: Codable {
    var schedules: [DailySchedule] = []
    
    init() {
        generateNext7Days()
    }
    
    // Generate schedule for next 7 days starting from today
    mutating func generateNext7Days() {
        schedules.removeAll()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                schedules.append(DailySchedule(date: date))
            }
        }
    }
    
    // Get today's schedule
    var todaysSchedule: DailySchedule? {
        return schedules.first { $0.isToday }
    }
    
    // Get schedule for a specific date
    func getSchedule(for date: Date) -> DailySchedule? {
        return schedules.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    // Update schedule for a specific date
    mutating func updateSchedule(for date: Date, with newSchedule: DailySchedule) {
        if let index = schedules.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            schedules[index] = newSchedule
        }
    }
    
    // Check if we need to roll forward (if oldest date is more than 1 day old)
    mutating func rollForwardIfNeeded() {
        guard let oldestDate = schedules.first?.date else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if oldestDate < today {
            // Need to roll forward
            let daysDifference = calendar.dateComponents([.day], from: oldestDate, to: today).day ?? 0
            
            if daysDifference >= 7 {
                // Complete regeneration if more than 7 days old
                generateNext7Days()
            } else {
                // Roll forward by removing old days and adding new ones
                schedules.removeFirst(daysDifference)
                
                let lastDate = schedules.last?.date ?? today
                for i in 1...daysDifference {
                    if let newDate = calendar.date(byAdding: .day, value: i, to: lastDate) {
                        schedules.append(DailySchedule(date: newDate))
                    }
                }
            }
        }
    }
    
    func toDictionary() -> [String: Any] {
        let schedulesArray = schedules.map { $0.toDictionary() }
        return [
            "schedules": schedulesArray
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> WeeklySchedule {
        var weeklySchedule = WeeklySchedule()
        
        if let schedulesArray = dict["schedules"] as? [[String: Any]] {
            weeklySchedule.schedules = schedulesArray.compactMap { DailySchedule.fromDictionary($0) }
        }
        
        // Ensure we have 7 days and roll forward if needed
        weeklySchedule.rollForwardIfNeeded()
        if weeklySchedule.schedules.count < 7 {
            weeklySchedule.generateNext7Days()
        }
        
        return weeklySchedule
    }
}

// MARK: - Legacy Models (for migration support)
struct OperatingHours: Codable {
    var monday: DayHours = DayHours()
    var tuesday: DayHours = DayHours()
    var wednesday: DayHours = DayHours()
    var thursday: DayHours = DayHours()
    var friday: DayHours = DayHours()
    var saturday: DayHours = DayHours()
    var sunday: DayHours = DayHours()
    
    func getDayHours(for day: WeekDay) -> DayHours {
        switch day {
        case .monday: return monday
        case .tuesday: return tuesday
        case .wednesday: return wednesday
        case .thursday: return thursday
        case .friday: return friday
        case .saturday: return saturday
        case .sunday: return sunday
        }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "monday": monday.toDictionary(),
            "tuesday": tuesday.toDictionary(),
            "wednesday": wednesday.toDictionary(),
            "thursday": thursday.toDictionary(),
            "friday": friday.toDictionary(),
            "saturday": saturday.toDictionary(),
            "sunday": sunday.toDictionary()
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> OperatingHours {
        var hours = OperatingHours()
        
        if let mondayDict = dict["monday"] as? [String: Any] {
            hours.monday = DayHours.fromDictionary(mondayDict)
        }
        if let tuesdayDict = dict["tuesday"] as? [String: Any] {
            hours.tuesday = DayHours.fromDictionary(tuesdayDict)
        }
        if let wednesdayDict = dict["wednesday"] as? [String: Any] {
            hours.wednesday = DayHours.fromDictionary(wednesdayDict)
        }
        if let thursdayDict = dict["thursday"] as? [String: Any] {
            hours.thursday = DayHours.fromDictionary(thursdayDict)
        }
        if let fridayDict = dict["friday"] as? [String: Any] {
            hours.friday = DayHours.fromDictionary(fridayDict)
        }
        if let saturdayDict = dict["saturday"] as? [String: Any] {
            hours.saturday = DayHours.fromDictionary(saturdayDict)
        }
        if let sundayDict = dict["sunday"] as? [String: Any] {
            hours.sunday = DayHours.fromDictionary(sundayDict)
        }
        
        return hours
    }
}

struct DayHours: Codable {
    var isOpen: Bool = false
    var openTime: String = "18:00" // 6 PM default
    var closeTime: String = "06:00" // 6 AM next day default
    
    var displayText: String {
        if !isOpen {
            return "Closed"
        }
        return "\(openTime) - \(closeTime)"
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "isOpen": isOpen,
            "openTime": openTime,
            "closeTime": closeTime
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> DayHours {
        return DayHours(
            isOpen: dict["isOpen"] as? Bool ?? false,
            openTime: dict["openTime"] as? String ?? "18:00",
            closeTime: dict["closeTime"] as? String ?? "06:00"
        )
    }
}

enum WeekDay: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var displayName: String {
        return rawValue
    }
    
    var shortName: String {
        return String(rawValue.prefix(3))
    }
}

// MARK: - SocialLinks
struct SocialLinks: Codable {
    var instagram: String = ""
    var twitter: String = ""
    var facebook: String = ""
    var website: String = ""
}

// MARK: - Enhanced Bar Model WITH 7-Day Schedule System
struct Bar: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let address: String
    
    // ENHANCED: Status system with simplified logic
    private var manualStatus: BarStatus? = nil  // nil means "follow schedule"
    private var _isFollowingSchedule: Bool = true  // ALWAYS true by default
    
    var description: String
    var socialLinks: SocialLinks
    var lastUpdated: Date
    var ownerID: String?
    var location: BarLocation?
    
    // Authentication fields
    var username: String
    var password: String
    
    // NEW: 7-day rolling schedule (replaces operatingHours)
    var weeklySchedule: WeeklySchedule = WeeklySchedule()
    
    // LEGACY: Keep for migration support only
    private var legacyOperatingHours: OperatingHours? = nil
    
    // Auto-transition timer fields (for manual overrides)
    var autoTransitionTime: Date?
    var pendingStatus: BarStatus?
    var isAutoTransitionActive: Bool = false
    
    // MARK: - MAIN STATUS PROPERTY (Simplified Logic)
    var status: BarStatus {
        get {
            // If there's an active manual override
            if !_isFollowingSchedule, let manualStatus = manualStatus {
                return manualStatus
            } else {
                // ALWAYS follow today's schedule by default
                return scheduleBasedStatus
            }
        }
    }
    
    // MARK: - PUBLIC ACCESS TO STATUS CONTROL STATE
    var isFollowingSchedule: Bool {
        get { _isFollowingSchedule }
        set { _isFollowingSchedule = newValue }
    }
    
    var currentManualStatus: BarStatus? {
        get { manualStatus }
    }
    
    // MARK: - Schedule-Based Status Logic (Updated for 7-Day System)
    var scheduleBasedStatus: BarStatus {
        // Ensure schedule is up to date
        var mutableSelf = self
        mutableSelf.weeklySchedule.rollForwardIfNeeded()
        
        guard let todaysSchedule = mutableSelf.weeklySchedule.todaysSchedule else {
            return .closed
        }
        
        // If not scheduled to be open today, ALWAYS closed
        guard todaysSchedule.isOpen else {
            return .closed
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Get opening and closing times for today
        guard let openTime = getTimeToday(from: todaysSchedule.openTime),
              let closeTime = getTimeToday(from: todaysSchedule.closeTime) else {
            return .closed
        }
        
        // Handle overnight hours (close time next day)
        let actualCloseTime = closeTime < openTime ?
            calendar.date(byAdding: .day, value: 1, to: closeTime)! : closeTime
        
        // Calculate transition times (15 minutes before)
        let openingSoonTime = calendar.date(byAdding: .minute, value: -15, to: openTime)!
        let closingSoonTime = calendar.date(byAdding: .minute, value: -15, to: actualCloseTime)!
        
        // Determine status based on current time
        if now < openingSoonTime {
            return .closed
        } else if now < openTime {
            return .openingSoon
        } else if now < closingSoonTime {
            return .open
        } else if now < actualCloseTime {
            return .closingSoon
        } else {
            return .closed
        }
    }
    
    // MARK: - STATUS CONTROL METHODS (Simplified)
    
    /// Set manual status override (Owner only)
    mutating func setManualStatusOverride(_ newStatus: BarStatus) {
        self.manualStatus = newStatus
        self._isFollowingSchedule = false
        self.lastUpdated = Date()
        self.cancelAutoTransition()
        print("🔧 Manual override set: \(newStatus.displayName)")
    }
    
    /// Return to following schedule (Owner only)
    mutating func returnToSchedule() {
        self._isFollowingSchedule = true
        self.manualStatus = nil
        self.lastUpdated = Date()
        self.cancelAutoTransition()
        print("📅 Now following schedule: \(scheduleBasedStatus.displayName)")
    }
    
    /// Update the 7-day schedule (Owner only)
    mutating func updateWeeklySchedule(_ newSchedule: WeeklySchedule) {
        self.weeklySchedule = newSchedule
        self.lastUpdated = Date()
        
        // If following schedule, this might change current status
        if _isFollowingSchedule {
            print("📅 Schedule updated, new status: \(scheduleBasedStatus.displayName)")
        }
    }
    
    /// Force refresh timestamp (for schedule changes)
    mutating func refreshTimestamp() {
        self.lastUpdated = Date()
        // Also roll forward schedule if needed
        self.weeklySchedule.rollForwardIfNeeded()
    }
    
    // MARK: - STATUS INFORMATION METHODS (Updated)
    
    /// Get detailed status info for UI
    var statusDisplayInfo: (status: BarStatus, source: String, description: String, isConflicting: Bool) {
        let currentStatus = status
        let scheduleStatus = scheduleBasedStatus
        
        if !isFollowingSchedule, let manualStatus = manualStatus {
            let isConflicting = manualStatus != scheduleStatus
            return (
                manualStatus,
                "Manual Override",
                "Owner set manually",
                isConflicting
            )
        } else {
            guard let todaysSchedule = weeklySchedule.todaysSchedule else {
                return (
                    scheduleStatus,
                    "Schedule",
                    "No schedule set for today",
                    false
                )
            }
            
            if todaysSchedule.isOpen {
                return (
                    scheduleStatus,
                    "Today's Schedule",
                    "Based on today's hours: \(todaysSchedule.displayText)",
                    false
                )
            } else {
                return (
                    scheduleStatus,
                    "Today's Schedule",
                    "Closed today",
                    false
                )
            }
        }
    }
    
    /// Check if status conflicts with schedule
    var isStatusConflictingWithSchedule: Bool {
        if !isFollowingSchedule {
            return status != scheduleBasedStatus
        }
        return false
    }
    
    /// Get today's operating status
    var isOpenToday: Bool {
        return weeklySchedule.todaysSchedule?.isOpen ?? false
    }
    
    var todaysSchedule: DailySchedule? {
        return weeklySchedule.todaysSchedule
    }
    
    // LEGACY: Support for old property access
    var todaysHours: DayHours {
        guard let todaysSchedule = weeklySchedule.todaysSchedule else {
            return DayHours()
        }
        
        return DayHours(
            isOpen: todaysSchedule.isOpen,
            openTime: todaysSchedule.openTime,
            closeTime: todaysSchedule.closeTime
        )
    }
    
    // MARK: - AUTO-TRANSITION METHODS (Keep existing)
    
    var shouldAutoTransition: Bool {
        guard isAutoTransitionActive,
              let transitionTime = autoTransitionTime,
              transitionTime <= Date() else {
            return false
        }
        return true
    }
    
    var timeUntilAutoTransition: TimeInterval? {
        guard isAutoTransitionActive,
              let transitionTime = autoTransitionTime else {
            return nil
        }
        let remaining = transitionTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : 0
    }
    
    mutating func startAutoTransition(to targetStatus: BarStatus, in minutes: Int = 60) {
        self.autoTransitionTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        self.pendingStatus = targetStatus
        self.isAutoTransitionActive = true
        self.lastUpdated = Date()
    }
    
    mutating func cancelAutoTransition() {
        self.autoTransitionTime = nil
        self.pendingStatus = nil
        self.isAutoTransitionActive = false
        self.lastUpdated = Date()
    }
    
    mutating func executeAutoTransition() -> Bool {
        guard shouldAutoTransition,
              let targetStatus = pendingStatus else {
            return false
        }
        
        self.setManualStatusOverride(targetStatus)
        return true
    }
    
    // MARK: - HELPER METHODS
    
    private func getTimeToday(from timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(byAdding: timeComponents, to: today)
    }
    
    // MARK: - MIGRATION HELPERS
    
    /// Migrate from old OperatingHours to new WeeklySchedule
    static func migrateOperatingHoursToWeeklySchedule(_ operatingHours: OperatingHours) -> WeeklySchedule {
        var weeklySchedule = WeeklySchedule()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate 7 days starting from today and apply old weekly pattern
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: today) else { continue }
            
            let weekday = calendar.component(.weekday, from: date)
            let oldWeekDay = mapCalendarWeekdayToOldWeekDay(weekday)
            let oldDayHours = operatingHours.getDayHours(for: oldWeekDay)
            
            var dailySchedule = DailySchedule(date: date)
            dailySchedule.isOpen = oldDayHours.isOpen
            dailySchedule.openTime = oldDayHours.openTime
            dailySchedule.closeTime = oldDayHours.closeTime
            
            weeklySchedule.schedules[i] = dailySchedule
        }
        
        print("🔄 Migrated operating hours to 7-day schedule")
        return weeklySchedule
    }
    
    private static func mapCalendarWeekdayToOldWeekDay(_ calendarWeekday: Int) -> WeekDay {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
    
    // MARK: - FIREBASE CONVERSION (Updated for 7-Day Schedule)
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "address": address,
            "description": description,
            "socialLinks": [
                "instagram": socialLinks.instagram,
                "twitter": socialLinks.twitter,
                "facebook": socialLinks.facebook,
                "website": socialLinks.website
            ],
            "lastUpdated": Timestamp(date: lastUpdated),
            "ownerID": ownerID ?? "",
            "username": username,
            "password": password,
            "isAutoTransitionActive": isAutoTransitionActive,
            "weeklySchedule": weeklySchedule.toDictionary(),
            "isFollowingSchedule": isFollowingSchedule
        ]
        
        // Add manual status if set
        if let manualStatus = manualStatus {
            dict["manualStatus"] = manualStatus.rawValue
        }
        
        // Add location data if available
        if let location = location {
            dict["location"] = [
                "country": location.country,
                "countryCode": location.countryCode,
                "city": location.city,
                "displayName": location.displayName
            ]
        }
        
        // Add auto-transition fields if active
        if let autoTransitionTime = autoTransitionTime {
            dict["autoTransitionTime"] = Timestamp(date: autoTransitionTime)
        }
        if let pendingStatus = pendingStatus {
            dict["pendingStatus"] = pendingStatus.rawValue
        }
        
        return dict
    }
    
    // MARK: - FIREBASE LOADING (Updated with Migration Support)
    
    static func fromDictionary(_ data: [String: Any], documentId: String) -> Bar? {
        guard let name = data["name"] as? String,
              let address = data["address"] as? String,
              let description = data["description"] as? String,
              let username = data["username"] as? String,
              let password = data["password"] as? String else {
            return nil
        }
        
        // Try to load new 7-day schedule first
        var weeklySchedule = WeeklySchedule()
        if let scheduleDict = data["weeklySchedule"] as? [String: Any] {
            weeklySchedule = WeeklySchedule.fromDictionary(scheduleDict)
        } else if let oldOperatingHours = data["operatingHours"] as? [String: Any] {
            // MIGRATION: Convert old operating hours to new schedule
            let operatingHours = OperatingHours.fromDictionary(oldOperatingHours)
            weeklySchedule = migrateOperatingHoursToWeeklySchedule(operatingHours)
            print("🔄 Migrated bar '\(name)' from operating hours to 7-day schedule")
        }
        
        // Location data
        var location: BarLocation?
        if let locationDict = data["location"] as? [String: Any],
           let country = locationDict["country"] as? String,
           let countryCode = locationDict["countryCode"] as? String,
           let city = locationDict["city"] as? String {
            location = BarLocation(country: country, countryCode: countryCode, city: city)
        }
        
        var bar = Bar(
            name: name,
            address: address,
            description: description,
            username: username,
            password: password,
            weeklySchedule: weeklySchedule,
            location: location
        )
        bar.id = documentId
        
        // Load status control state
        bar._isFollowingSchedule = data["isFollowingSchedule"] as? Bool ?? true // DEFAULT: follow schedule
        
        if let manualStatusString = data["manualStatus"] as? String,
           let manualStatus = BarStatus(rawValue: manualStatusString) {
            bar.manualStatus = manualStatus
        }
        
        // MIGRATION: Handle old status field from existing bars
        if let oldStatusString = data["status"] as? String,
           let oldStatus = BarStatus(rawValue: oldStatusString),
           bar.manualStatus == nil {
            // Migrate old manual status but prioritize schedule by default
            if oldStatus != bar.scheduleBasedStatus {
                bar.manualStatus = oldStatus
                bar._isFollowingSchedule = false
                print("🔄 Migrated bar \(name) - found conflict, keeping manual override")
            }
        }
        
        // Social links
        if let socialData = data["socialLinks"] as? [String: Any] {
            bar.socialLinks.instagram = socialData["instagram"] as? String ?? ""
            bar.socialLinks.twitter = socialData["twitter"] as? String ?? ""
            bar.socialLinks.facebook = socialData["facebook"] as? String ?? ""
            bar.socialLinks.website = socialData["website"] as? String ?? ""
        }
        
        // Last updated
        if let timestamp = data["lastUpdated"] as? Timestamp {
            bar.lastUpdated = timestamp.dateValue()
        }
        
        // Auto-transition fields
        bar.isAutoTransitionActive = data["isAutoTransitionActive"] as? Bool ?? false
        
        if let autoTransitionTimestamp = data["autoTransitionTime"] as? Timestamp {
            bar.autoTransitionTime = autoTransitionTimestamp.dateValue()
        }
        
        if let pendingStatusString = data["pendingStatus"] as? String,
           let pendingStatus = BarStatus(rawValue: pendingStatusString) {
            bar.pendingStatus = pendingStatus
        }
        
        bar.ownerID = data["ownerID"] as? String
        
        return bar
    }
    
    // MARK: - INITIALIZATION METHODS (Updated for 7-Day Schedule)
    
    /// PRIMARY INITIALIZER - Always starts following 7-day schedule
    init(name: String, address: String, description: String = "", socialLinks: SocialLinks = SocialLinks(), ownerID: String? = nil, username: String, password: String, weeklySchedule: WeeklySchedule = WeeklySchedule(), location: BarLocation? = nil) {
        self.name = name
        self.address = address
        self.description = description
        self.socialLinks = socialLinks
        self.lastUpdated = Date()
        self.ownerID = ownerID
        self.username = username
        self.password = password
        self.weeklySchedule = weeklySchedule
        self.location = location
        
        // CRITICAL: Always start following schedule
        self._isFollowingSchedule = true
        self.manualStatus = nil
        
        print("✅ Created new bar '\(name)' - following 7-day schedule by default")
    }
    
    // MARK: - BACKWARD COMPATIBILITY INITIALIZERS (Deprecated but supported)
    
    /// DEPRECATED: Use primary initializer instead
    init(name: String, address: String, status: BarStatus, description: String = "", socialLinks: SocialLinks = SocialLinks(), ownerID: String? = nil, username: String, password: String, operatingHours: OperatingHours = OperatingHours(), location: BarLocation? = nil) {
        
        // Convert old operating hours to new 7-day schedule
        let migratedSchedule = Bar.migrateOperatingHoursToWeeklySchedule(operatingHours)
        
        self.init(name: name, address: address, description: description, socialLinks: socialLinks, ownerID: ownerID, username: username, password: password, weeklySchedule: migratedSchedule, location: location)
        
        // Only set manual override if it differs from schedule
        if status != scheduleBasedStatus {
            self.manualStatus = status
            self._isFollowingSchedule = false
            print("⚠️ Created bar '\(name)' with manual override: \(status.displayName)")
        }
    }
    
    /// DEPRECATED: Use primary initializer instead
    init(name: String, latitude: Double, longitude: Double, address: String, status: BarStatus = .closed, description: String = "", password: String) {
        self.init(name: name, address: address, description: description, username: name, password: password)
        
        // Only set manual override if it differs from schedule
        if status != scheduleBasedStatus {
            self.manualStatus = status
            self._isFollowingSchedule = false
            print("⚠️ Created bar '\(name)' with legacy manual override: \(status.displayName)")
        }
    }
}
