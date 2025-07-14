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

// MARK: - Enhanced Bar Model WITH Location Support
struct Bar: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let address: String
    var status: BarStatus
    var description: String
    var socialLinks: SocialLinks
    var lastUpdated: Date
    var ownerID: String?
    
    // 🌍 NEW: Location information
    var location: BarLocation?
    
    // Authentication fields
    var username: String
    var password: String
    
    // Operating hours
    var operatingHours: OperatingHours = OperatingHours()
    
    // Auto-transition timer fields
    var autoTransitionTime: Date?           // When the auto-change should happen
    var pendingStatus: BarStatus?           // What status to change to automatically
    var isAutoTransitionActive: Bool = false // Whether a timer is currently running
    
    // Computed property to check if auto-transition should trigger
    var shouldAutoTransition: Bool {
        guard isAutoTransitionActive,
              let transitionTime = autoTransitionTime,
              transitionTime <= Date() else {
            return false
        }
        return true
    }
    
    // Computed property for remaining time until auto-transition
    var timeUntilAutoTransition: TimeInterval? {
        guard isAutoTransitionActive,
              let transitionTime = autoTransitionTime else {
            return nil
        }
        let remaining = transitionTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : 0
    }
    
    // Check if bar is open today based on regular hours
    var isOpenToday: Bool {
        let today = getCurrentWeekDay()
        return operatingHours.getDayHours(for: today).isOpen
    }
    
    // Get today's operating hours
    var todaysHours: DayHours {
        let today = getCurrentWeekDay()
        return operatingHours.getDayHours(for: today)
    }
    
    init(name: String, address: String, status: BarStatus = .closed, description: String = "", socialLinks: SocialLinks = SocialLinks(), ownerID: String? = nil, username: String, password: String, operatingHours: OperatingHours = OperatingHours(), location: BarLocation? = nil) {
        self.name = name
        self.address = address
        self.status = status
        self.description = description
        self.socialLinks = socialLinks
        self.lastUpdated = Date()
        self.ownerID = ownerID
        self.username = username
        self.password = password
        self.operatingHours = operatingHours
        self.location = location
    }
    
    // Mutating function to start auto-transition timer
    mutating func startAutoTransition(to targetStatus: BarStatus, in minutes: Int = 60) {
        self.autoTransitionTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        self.pendingStatus = targetStatus
        self.isAutoTransitionActive = true
        self.lastUpdated = Date()
    }
    
    // Mutating function to cancel auto-transition
    mutating func cancelAutoTransition() {
        self.autoTransitionTime = nil
        self.pendingStatus = nil
        self.isAutoTransitionActive = false
        self.lastUpdated = Date()
    }
    
    // Mutating function to execute auto-transition
    mutating func executeAutoTransition() -> Bool {
        guard shouldAutoTransition,
              let targetStatus = pendingStatus else {
            return false
        }
        
        self.status = targetStatus
        self.autoTransitionTime = nil
        self.pendingStatus = nil
        self.isAutoTransitionActive = false
        self.lastUpdated = Date()
        
        return true
    }
    
    // Convert to Firebase document
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "address": address,
            "status": status.rawValue,
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
            "operatingHours": operatingHours.toDictionary()
        ]
        
        // 🌍 Add location data if available
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
    
    // Create from Firebase document
    static func fromDictionary(_ data: [String: Any], documentId: String) -> Bar? {
        guard let name = data["name"] as? String,
              let address = data["address"] as? String,
              let statusString = data["status"] as? String,
              let status = BarStatus(rawValue: statusString),
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
        
        // 🌍 Parse location data
        var location: BarLocation?
        if let locationDict = data["location"] as? [String: Any],
           let country = locationDict["country"] as? String,
           let countryCode = locationDict["countryCode"] as? String,
           let city = locationDict["city"] as? String {
            location = BarLocation(country: country, countryCode: countryCode, city: city)
        }
        
        var bar = Bar(name: name, address: address, status: status, description: description, username: username, password: password, operatingHours: operatingHours, location: location)
        bar.id = documentId
        
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
    
    // Helper function to get current weekday
    private func getCurrentWeekDay() -> WeekDay {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        switch weekday {
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
}
