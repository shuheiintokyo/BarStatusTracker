import Foundation
import FirebaseFirestore

// MARK: - Simplified Bar Model
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
    
    // Schedule Management - Simplified
    var weeklySchedule: WeeklySchedule = WeeklySchedule()
    
    // Status Management - Simplified
    private var _manualStatus: BarStatus?
    private var _isFollowingSchedule: Bool = true
    
    // MARK: - Clean Status Logic
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
    
    var manualStatus: BarStatus? {
        get { _manualStatus }
    }
    
    // MARK: - Public Methods
    mutating func setManualStatus(_ status: BarStatus) {
        _manualStatus = status
        _isFollowingSchedule = false
        updateTimestamp()
    }
    
    mutating func followSchedule() {
        _isFollowingSchedule = true
        _manualStatus = nil
        updateTimestamp()
    }
    
    mutating func updateSchedule(_ schedule: WeeklySchedule) {
        weeklySchedule = schedule
        updateTimestamp()
    }
    
    private mutating func updateTimestamp() {
        lastUpdated = Date()
    }
    
    // MARK: - Computed Properties
    var todaysSchedule: DailySchedule? {
        return weeklySchedule.todaysSchedule
    }
    
    var isOpenToday: Bool {
        return todaysSchedule?.isOpen ?? false
    }
    
    var scheduleBasedStatus: BarStatus {
        return ScheduleCalculator.calculateStatus(for: weeklySchedule)
    }
    
    var hasStatusConflict: Bool {
        return !isFollowingSchedule && status != scheduleBasedStatus
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
}

// MARK: - Schedule Calculator (Separated Logic)
struct ScheduleCalculator {
    static func calculateStatus(for schedule: WeeklySchedule) -> BarStatus {
        guard let todaysSchedule = schedule.todaysSchedule, todaysSchedule.isOpen else {
            return .closed
        }
        
        let now = Date()
        let calendar = Calendar.current
        
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
