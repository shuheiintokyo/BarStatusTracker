import Foundation

// MARK: - Weekly Schedule System

struct WeeklySchedule: Codable {
    var schedules: [DailySchedule]
    
    init() {
        // Create 7 days starting from today
        let calendar = Calendar.current
        let today = Date()
        
        self.schedules = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            return DailySchedule(date: date)
        }
    }
    
    var todaysSchedule: DailySchedule? {
        return schedules.first { $0.isToday }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "schedules": schedules.map { $0.toDictionary() }
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> WeeklySchedule? {
        guard let schedulesData = dict["schedules"] as? [[String: Any]] else {
            return nil
        }
        
        var schedule = WeeklySchedule()
        let decodedSchedules = schedulesData.compactMap { DailySchedule.fromDictionary($0) }
        
        if decodedSchedules.count == 7 {
            schedule.schedules = decodedSchedules
        }
        
        return schedule
    }
}

struct DailySchedule: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var isOpen: Bool = false
    var openTime: String = "18:00"
    var closeTime: String = "02:00"
    
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
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var displayText: String {
        if isOpen {
            let openFormatted = formatTimeForDisplay(openTime)
            let closeFormatted = formatTimeForDisplay(closeTime)
            return "\(openFormatted) - \(closeFormatted)"
        } else {
            return "Closed"
        }
    }
    
    private func formatTimeForDisplay(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let time = formatter.date(from: timeString) else {
            return timeString
        }
        
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    func toDictionary() -> [String: Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return [
            "date": formatter.string(from: date),
            "isOpen": isOpen,
            "openTime": openTime,
            "closeTime": closeTime
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> DailySchedule? {
        guard let dateString = dict["date"] as? String,
              let isOpen = dict["isOpen"] as? Bool,
              let openTime = dict["openTime"] as? String,
              let closeTime = dict["closeTime"] as? String else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return nil
        }
        
        var schedule = DailySchedule(date: date)
        schedule.isOpen = isOpen
        schedule.openTime = openTime
        schedule.closeTime = closeTime
        
        return schedule
    }
}

// MARK: - Social Links

struct SocialLinks: Codable {
    var instagram: String = ""
    var twitter: String = ""
    var facebook: String = ""
    var website: String = ""
    
    init() {}
    
    init(instagram: String = "", twitter: String = "", facebook: String = "", website: String = "") {
        self.instagram = instagram
        self.twitter = twitter
        self.facebook = facebook
        self.website = website
    }
    
    func toDictionary() -> [String: String] {
        return [
            "instagram": instagram,
            "twitter": twitter,
            "facebook": facebook,
            "website": website
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> SocialLinks {
        return SocialLinks(
            instagram: dict["instagram"] as? String ?? "",
            twitter: dict["twitter"] as? String ?? "",
            facebook: dict["facebook"] as? String ?? "",
            website: dict["website"] as? String ?? ""
        )
    }
}

// MARK: - Legacy Operating Hours (for backward compatibility)

struct OperatingHours: Codable {
    var monday: DayHours = DayHours()
    var tuesday: DayHours = DayHours()
    var wednesday: DayHours = DayHours()
    var thursday: DayHours = DayHours()
    var friday: DayHours = DayHours()
    var saturday: DayHours = DayHours()
    var sunday: DayHours = DayHours()
    
    // Convert to new WeeklySchedule format
    func toWeeklySchedule() -> WeeklySchedule {
        var schedule = WeeklySchedule()
        let dayHours = [sunday, monday, tuesday, wednesday, thursday, friday, saturday]
        
        for (index, dayHour) in dayHours.enumerated() {
            if index < schedule.schedules.count {
                schedule.schedules[index].isOpen = dayHour.isOpen
                schedule.schedules[index].openTime = dayHour.openTime
                schedule.schedules[index].closeTime = dayHour.closeTime
            }
        }
        
        return schedule
    }
}

struct DayHours: Codable {
    var isOpen: Bool = false
    var openTime: String = "18:00"
    var closeTime: String = "02:00"
    
    var displayText: String {
        if isOpen {
            return "\(openTime) - \(closeTime)"
        } else {
            return "Closed"
        }
    }
}

enum WeekDay: String, CaseIterable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    
    var displayName: String {
        return self.rawValue
    }
    
    var shortName: String {
        return String(self.rawValue.prefix(3))
    }
}
