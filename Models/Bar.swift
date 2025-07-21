import Foundation
import FirebaseFirestore

// MARK: - Complete Bar Model with Firebase Integration

struct Bar: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let address: String
    var description: String
    var socialLinks: SocialLinks
    var lastUpdated: Date
    var ownerID: String?
    var location: BarLocation?
    
    // Authentication
    var username: String
    var password: String
    
    // Schedule Management
    var weeklySchedule: WeeklySchedule = WeeklySchedule()
    
    // Status Management
    private var _manualStatus: BarStatus?
    private var _isFollowingSchedule: Bool = true
    
    // Auto-transition properties
    var pendingStatus: BarStatus?
    var transitionTime: Date?
    
    // MARK: - Status Logic
    
    var status: BarStatus {
        if !_isFollowingSchedule, let manualStatus = _manualStatus {
            return manualStatus
        }
        return ScheduleCalculator.calculateStatus(for: weeklySchedule)
    }
    
    var isFollowingSchedule: Bool {
        get { _isFollowingSchedule }
        set { _isFollowingSchedule = newValue }
    }
    
    var currentManualStatus: BarStatus? {
        get { _manualStatus }
    }
    
    var scheduleBasedStatus: BarStatus {
        return ScheduleCalculator.calculateStatus(for: weeklySchedule)
    }
    
    var isStatusConflictingWithSchedule: Bool {
        return !isFollowingSchedule && status != scheduleBasedStatus
    }
    
    var isAutoTransitionActive: Bool {
        return pendingStatus != nil && transitionTime != nil
    }
    
    // MARK: - Computed Properties
    
    var todaysSchedule: DailySchedule? {
        return weeklySchedule.todaysSchedule
    }
    
    var isOpenToday: Bool {
        return todaysSchedule?.isOpen ?? false
    }
    
    // MARK: - Public Methods
    
    mutating func setManualStatus(_ status: BarStatus) {
        _manualStatus = status
        _isFollowingSchedule = false
        clearAutoTransition()
        updateTimestamp()
    }
    
    mutating func followSchedule() {
        _isFollowingSchedule = true
        _manualStatus = nil
        clearAutoTransition()
        updateTimestamp()
    }
    
    mutating func updateSchedule(_ schedule: WeeklySchedule) {
        weeklySchedule = schedule
        updateTimestamp()
    }
    
    mutating func setAutoTransition(to status: BarStatus, at time: Date) {
        pendingStatus = status
        transitionTime = time
        updateTimestamp()
    }
    
    mutating func clearAutoTransition() {
        pendingStatus = nil
        transitionTime = nil
    }
    
    private mutating func updateTimestamp() {
        lastUpdated = Date()
    }
    
    // MARK: - Initializers
    
    init(name: String, address: String, description: String = "", username: String, password: String, location: BarLocation? = nil) {
        self.name = name
        self.address = address
        self.description = description
        self.socialLinks = SocialLinks()
        self.lastUpdated = Date()
        self.username = username
        self.password = password
        self.location = location
        self._isFollowingSchedule = true
        self._manualStatus = nil
    }
    
    init(name: String, address: String, description: String = "", username: String, password: String, weeklySchedule: WeeklySchedule, location: BarLocation? = nil) {
        self.name = name
        self.address = address
        self.description = description
        self.socialLinks = SocialLinks()
        self.lastUpdated = Date()
        self.username = username
        self.password = password
        self.weeklySchedule = weeklySchedule
        self.location = location
        self._isFollowingSchedule = true
        self._manualStatus = nil
    }
    
    // MARK: - Firebase Serialization
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "address": address,
            "description": description,
            "socialLinks": socialLinks.toDictionary(),
            "lastUpdated": Timestamp(date: lastUpdated),
            "username": username,
            "password": password,
            "weeklySchedule": weeklySchedule.toDictionary(),
            "isFollowingSchedule": _isFollowingSchedule
        ]
        
        if let ownerID = ownerID {
            dict["ownerID"] = ownerID
        }
        
        if let location = location {
            dict["location"] = [
                "country": location.country,
                "countryCode": location.countryCode,
                "city": location.city,
                "displayName": location.displayName
            ]
        }
        
        if let manualStatus = _manualStatus {
            dict["manualStatus"] = manualStatus.rawValue
        }
        
        if let pendingStatus = pendingStatus {
            dict["pendingStatus"] = pendingStatus.rawValue
        }
        
        if let transitionTime = transitionTime {
            dict["transitionTime"] = Timestamp(date: transitionTime)
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], documentId: String? = nil) -> Bar? {
        guard let name = dict["name"] as? String,
              let address = dict["address"] as? String,
              let username = dict["username"] as? String,
              let password = dict["password"] as? String else {
            return nil
        }
        
        let description = dict["description"] as? String ?? ""
        let id = documentId ?? (dict["id"] as? String) ?? UUID().uuidString
        
        // Parse social links
        let socialLinks: SocialLinks
        if let socialLinksDict = dict["socialLinks"] as? [String: Any] {
            socialLinks = SocialLinks.fromDictionary(socialLinksDict)
        } else {
            socialLinks = SocialLinks()
        }
        
        // Parse last updated
        let lastUpdated: Date
        if let timestamp = dict["lastUpdated"] as? Timestamp {
            lastUpdated = timestamp.dateValue()
        } else {
            lastUpdated = Date()
        }
        
        // Parse weekly schedule
        let weeklySchedule: WeeklySchedule
        if let scheduleDict = dict["weeklySchedule"] as? [String: Any],
           let parsedSchedule = WeeklySchedule.fromDictionary(scheduleDict) {
            weeklySchedule = parsedSchedule
        } else {
            weeklySchedule = WeeklySchedule()
        }
        
        // Parse location
        let location: BarLocation?
        if let locationDict = dict["location"] as? [String: Any],
           let country = locationDict["country"] as? String,
           let countryCode = locationDict["countryCode"] as? String,
           let city = locationDict["city"] as? String {
            location = BarLocation(country: country, countryCode: countryCode, city: city)
        } else {
            location = nil
        }
        
        // Create bar
        var bar = Bar(
            name: name,
            address: address,
            description: description,
            username: username,
            password: password,
            weeklySchedule: weeklySchedule,
            location: location
        )
        
        bar.id = id
        bar.socialLinks = socialLinks
        bar.lastUpdated = lastUpdated
        bar.ownerID = dict["ownerID"] as? String
        
        // Parse status management
        bar._isFollowingSchedule = dict["isFollowingSchedule"] as? Bool ?? true
        
        if let manualStatusString = dict["manualStatus"] as? String,
           let manualStatus = BarStatus(rawValue: manualStatusString) {
            bar._manualStatus = manualStatus
        }
        
        if let pendingStatusString = dict["pendingStatus"] as? String,
           let pendingStatus = BarStatus(rawValue: pendingStatusString) {
            bar.pendingStatus = pendingStatus
        }
        
        if let transitionTimestamp = dict["transitionTime"] as? Timestamp {
            bar.transitionTime = transitionTimestamp.dateValue()
        }
        
        return bar
    }
    
    // MARK: - Debug Helper
    
    func debugScheduleStatus() -> String {
        let today = todaysSchedule?.dayName ?? "Unknown"
        let scheduleStatus = scheduleBasedStatus.displayName
        let actualStatus = status.displayName
        let following = isFollowingSchedule ? "YES" : "NO"
        
        return """
        Debug Info for \(name):
        Today: \(today)
        Schedule Status: \(scheduleStatus)
        Actual Status: \(actualStatus)
        Following Schedule: \(following)
        Manual Status: \(_manualStatus?.displayName ?? "None")
        Auto-transition: \(isAutoTransitionActive ? "Active" : "Inactive")
        """
    }
}

// MARK: - Schedule Calculator (Enhanced)

struct ScheduleCalculator {
    static func calculateStatus(for schedule: WeeklySchedule) -> BarStatus {
        guard let todaysSchedule = schedule.todaysSchedule, todaysSchedule.isOpen else {
            return .closed
        }
        
        let now = Date()
        
        // FIXED: Use calendar variable properly instead of letting it be unused
        guard let openTime = parseTime(todaysSchedule.openTime, for: now),
              let closeTime = parseTime(todaysSchedule.closeTime, for: now) else {
            return .closed
        }
        
        return calculateStatusFromTimes(current: now, open: openTime, close: closeTime)
    }
    
    private static func calculateStatusFromTimes(current: Date, open: Date, close: Date) -> BarStatus {
        let calendar = Calendar.current
        let isOvernightSchedule = close <= open
        
        if isOvernightSchedule {
            return calculateOvernightStatus(current: current, open: open, close: close, calendar: calendar)
        } else {
            return calculateSameDayStatus(current: current, open: open, close: close, calendar: calendar)
        }
    }
    
    private static func calculateOvernightStatus(current: Date, open: Date, close: Date, calendar: Calendar) -> BarStatus {
        let isInOpenPeriod = current >= open || current < close
        
        if !isInOpenPeriod {
            // Check if opening soon
            let openingSoonTime = calendar.date(byAdding: .minute, value: -15, to: open)!
            return current >= openingSoonTime ? .openingSoon : .closed
        }
        
        // Check if closing soon
        let relevantCloseTime = current >= open ?
            calendar.date(byAdding: .day, value: 1, to: close)! : close
        let closingSoonTime = calendar.date(byAdding: .minute, value: -15, to: relevantCloseTime)!
        
        return current >= closingSoonTime ? .closingSoon : .open
    }
    
    private static func calculateSameDayStatus(current: Date, open: Date, close: Date, calendar: Calendar) -> BarStatus {
        let openingSoonTime = calendar.date(byAdding: .minute, value: -15, to: open)!
        let closingSoonTime = calendar.date(byAdding: .minute, value: -15, to: close)!
        
        if current < openingSoonTime {
            return .closed
        } else if current < open {
            return .openingSoon
        } else if current < closingSoonTime {
            return .open
        } else if current < close {
            return .closingSoon
        } else {
            return .closed
        }
    }
    
    private static func parseTime(_ timeString: String, for date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        guard let time = formatter.date(from: timeString) else { return nil }
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(byAdding: timeComponents, to: today)
    }
}
