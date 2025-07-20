import Foundation
import FirebaseFirestore

// MARK: - Operating Hours Models
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
    
    mutating func setDayHours(for day: WeekDay, hours: DayHours) {
        switch day {
        case .monday: monday = hours
        case .tuesday: tuesday = hours
        case .wednesday: wednesday = hours
        case .thursday: thursday = hours
        case .friday: friday = hours
        case .saturday: saturday = hours
        case .sunday: sunday = hours
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

// MARK: - Enhanced Bar Model WITH Consistent Status Logic
struct Bar: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let address: String
    
    // ENHANCED: Status system with strict logic
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
    
    // Operating hours
    var operatingHours: OperatingHours = OperatingHours()
    
    // Auto-transition timer fields (for manual overrides)
    var autoTransitionTime: Date?
    var pendingStatus: BarStatus?
    var isAutoTransitionActive: Bool = false
    
    // MARK: - MAIN STATUS PROPERTY (Always computed, consistent logic)
    var status: BarStatus {
        get {
            // If there's an active manual override AND it's from owner controls
            if !_isFollowingSchedule, let manualStatus = manualStatus {
                return manualStatus
            } else {
                // ALWAYS follow schedule by default
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
    
    // MARK: - Schedule-Based Status Logic (Enhanced)
    var scheduleBasedStatus: BarStatus {
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = getCurrentWeekDay()
        let todayHours = operatingHours.getDayHours(for: currentWeekday)
        
        // If not scheduled to be open today, ALWAYS closed
        guard todayHours.isOpen else {
            return .closed
        }
        
        // Get opening and closing times for today
        guard let openTime = getTimeToday(from: todayHours.openTime),
              let closeTime = getTimeToday(from: todayHours.closeTime) else {
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
    
    // MARK: - STATUS CONTROL METHODS (Only for Owner)
    
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
    
    /// Force refresh timestamp (for schedule changes)
    mutating func refreshTimestamp() {
        self.lastUpdated = Date()
    }
    
    // MARK: - STATUS INFORMATION METHODS
    
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
            let today = getCurrentWeekDay()
            let todayHours = operatingHours.getDayHours(for: today)
            
            if todayHours.isOpen {
                return (
                    scheduleStatus,
                    "Schedule",
                    "Based on \(today.displayName) hours",
                    false
                )
            } else {
                return (
                    scheduleStatus,
                    "Schedule",
                    "Closed on \(today.displayName)s",
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
        let today = getCurrentWeekDay()
        return operatingHours.getDayHours(for: today).isOpen
    }
    
    var todaysHours: DayHours {
        let today = getCurrentWeekDay()
        return operatingHours.getDayHours(for: today)
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
    
    // MARK: - FIREBASE CONVERSION (Updated)
    
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
            "operatingHours": operatingHours.toDictionary(),
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
    
    // MARK: - FIREBASE LOADING (Updated with proper defaults)
    
    static func fromDictionary(_ data: [String: Any], documentId: String) -> Bar? {
        guard let name = data["name"] as? String,
              let address = data["address"] as? String,
              let description = data["description"] as? String,
              let username = data["username"] as? String,
              let password = data["password"] as? String else {
            return nil
        }
        
        // Operating hours
        var operatingHours = OperatingHours()
        if let hoursDict = data["operatingHours"] as? [String: Any] {
            operatingHours = OperatingHours.fromDictionary(hoursDict)
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
            operatingHours: operatingHours,
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
    
    // MARK: - INITIALIZATION METHODS (Updated to ensure proper defaults)
    
    /// PRIMARY INITIALIZER - Always starts following schedule
    init(name: String, address: String, description: String = "", socialLinks: SocialLinks = SocialLinks(), ownerID: String? = nil, username: String, password: String, operatingHours: OperatingHours = OperatingHours(), location: BarLocation? = nil) {
        self.name = name
        self.address = address
        self.description = description
        self.socialLinks = socialLinks
        self.lastUpdated = Date()
        self.ownerID = ownerID
        self.username = username
        self.password = password
        self.operatingHours = operatingHours
        self.location = location
        
        // CRITICAL: Always start following schedule
        self.isFollowingSchedule = true
        self.manualStatus = nil
        
        print("✅ Created new bar '\(name)' - following schedule by default")
    }
    
    // MARK: - BACKWARD COMPATIBILITY INITIALIZERS (Deprecated but supported)
    
    /// DEPRECATED: Use primary initializer instead
    init(name: String, address: String, status: BarStatus, description: String = "", socialLinks: SocialLinks = SocialLinks(), ownerID: String? = nil, username: String, password: String, operatingHours: OperatingHours = OperatingHours(), location: BarLocation? = nil) {
        self.init(name: name, address: address, description: description, socialLinks: socialLinks, ownerID: ownerID, username: username, password: password, operatingHours: operatingHours, location: location)
        
        // Only set manual override if it differs from schedule
        if status != scheduleBasedStatus {
            self.manualStatus = status
            self.isFollowingSchedule = false
            print("⚠️ Created bar '\(name)' with manual override: \(status.displayName)")
        }
    }
    
    /// DEPRECATED: Use primary initializer instead
    init(name: String, latitude: Double, longitude: Double, address: String, status: BarStatus = .closed, description: String = "", password: String) {
        self.init(name: name, address: address, description: description, username: name, password: password)
        
        // Only set manual override if it differs from schedule
        if status != scheduleBasedStatus {
            self.manualStatus = status
            self.isFollowingSchedule = false
            print("⚠️ Created bar '\(name)' with legacy manual override: \(status.displayName)")
        }
    }
}
