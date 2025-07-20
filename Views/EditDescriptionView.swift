// MARK: - Updated EditDescriptionView (minimal changes needed)

import SwiftUI

struct EditDescriptionView: View {
    @Binding var description: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $description)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding()
                
                // UPDATED: Tip text to mention schedule instead of operating hours
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Tell customers about your bar's atmosphere and specialties")
                        Text("• Mention any special events or weekly features")
                        Text("• Your 7-day schedule shows when you're open")
                        Text("• Keep descriptions concise and engaging")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Edit Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(description)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Updated BarGridItem (check for any schedule references)

extension BarGridItem {
    // If BarGridItem shows any schedule info, update to use new system:
    
    // OLD (if exists):
    // let todaysHours = bar.todaysHours
    
    // NEW:
    // let todaysSchedule = bar.todaysSchedule
    
    // Most likely this component doesn't need changes since it probably
    // just shows status color and name, but check for any schedule displays
}

// MARK: - Updated MainContentView (check for schedule displays)

extension MainContentView {
    // Check if MainContentView shows any schedule information
    // If it does, update from:
    
    // OLD:
    // bar.operatingHours.getDayHours(for: today)
    
    // NEW:
    // bar.todaysSchedule
    
    // Example update if showing "open today" info:
    /*
    private var openTodayText: String {
        let openBars = barViewModel.getAllBars().filter { bar in
            // OLD:
            // let today = getCurrentWeekDay()
            // return bar.operatingHours.getDayHours(for: today).isOpen
            
            // NEW:
            return bar.isOpenToday
        }
        
        return "\(openBars.count) bars open today"
    }
    */
}

// MARK: - Check DualTimeSlider Compatibility

extension DualTimeSlider {
    // DualTimeSlider should work as-is since it just handles time strings
    // But verify it works with DailySchedule bindings:
    
    /*
    // Usage in new system:
    DualTimeSlider(
        openTime: Binding(
            get: { dailySchedule.openTime },
            set: { dailySchedule.openTime = $0 }
        ),
        closeTime: Binding(
            get: { dailySchedule.closeTime },
            set: { dailySchedule.closeTime = $0 }
        )
    )
    */
    
    // If any issues, the timeSlots array might need verification:
    private let timeSlots = [
        "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
        "21:00", "21:30", "22:00", "22:30", "23:00", "23:30",
        "00:00", "00:30", "01:00", "01:30", "02:00", "02:30",
        "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00"
    ]
    // ✅ This should work fine with the new system
}

// MARK: - Update SearchBarsView (minimal changes likely)

extension SearchBarsView {
    // Check if SearchBarsView shows any schedule information in search results
    // Most likely just needs verification that existing filtering still works:
    
    /*
    private var filteredBars: [Bar] {
        let allBars = barViewModel.getAllBars()
        if searchText.isEmpty {
            return allBars
        }
        return allBars.filter { bar in
            bar.name.localizedCaseInsensitiveContains(searchText) ||
            bar.address.localizedCaseInsensitiveContains(searchText) ||
            (bar.location?.city.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (bar.location?.country.localizedCaseInsensitiveContains(searchText) ?? false)
            // NEW: Could add schedule-based filtering if needed:
            // || bar.todaysSchedule?.displayText.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    */
}

// MARK: - Update BrowseByLocationView (minimal changes likely)

extension BrowseByLocationView {
    // Check LocationBarRow for any schedule display
    // Update from old system to new if needed:
    
    /*
    // In LocationBarRow, if showing schedule info:
    
    // OLD:
    let today = getCurrentWeekDay()
    let todaysHours = bar.operatingHours.getDayHours(for: today)
    Text(todaysHours.displayText)
    
    // NEW:
    if let todaysSchedule = bar.todaysSchedule {
        Text(todaysSchedule.displayText)
    } else {
        Text("No schedule")
    }
    */
}

// MARK: - Analytics Updates (if using analytics)

extension BasicDeviceAnalytics {
    // Add new analytics events for 7-day schedule system:
    
    func logScheduleCreated(barId: String, daysCount: Int) {
        // Log when a new 7-day schedule is created
        print("📊 Schedule Created: barId=\(barId), days=\(daysCount)")
    }
    
    func logScheduleUpdated(barId: String, dayUpdated: String, wasOpen: Bool, nowOpen: Bool) {
        // Log when individual days are updated
        print("📊 Schedule Updated: barId=\(barId), day=\(dayUpdated), \(wasOpen ? "open" : "closed") → \(nowOpen ? "open" : "closed")")
    }
    
    func logManualOverride(barId: String, fromStatus: String, toStatus: String) {
        // Log when manual overrides are used
        print("📊 Manual Override: barId=\(barId), \(fromStatus) → \(toStatus)")
    }
    
    func logReturnToSchedule(barId: String, manualStatus: String, scheduleStatus: String) {
        // Log when returning to schedule
        print("📊 Return to Schedule: barId=\(barId), manual=\(manualStatus), schedule=\(scheduleStatus)")
    }
    
    func logMigrationCompleted(barId: String, migratedDays: Int) {
        // Log successful migration from old system
        print("📊 Migration Completed: barId=\(barId), migratedDays=\(migratedDays)")
    }
}

// MARK: - UserPreferencesManager Updates (if storing schedule preferences)

extension UserPreferencesManager {
    // Add any new preferences related to 7-day schedule system:
    
    func setSchedulePreferences(showWeekView: Bool = true, highlightToday: Bool = true) {
        // Store user preferences for schedule display
        UserDefaults.standard.set(showWeekView, forKey: "showWeekView")
        UserDefaults.standard.set(highlightToday, forKey: "highlightToday")
    }
    
    var showWeekView: Bool {
        UserDefaults.standard.bool(forKey: "showWeekView")
    }
    
    var highlightToday: Bool {
        UserDefaults.standard.bool(forKey: "highlightToday")
    }
}

// MARK: - Testing Helpers (for debugging and testing)

#if DEBUG
extension BarViewModel {
    // Add testing methods for new schedule system:
    
    func createTestBarWith7DaySchedule() -> Bar {
        var schedule = WeeklySchedule()
        
        // Set alternating open/closed days for testing
        for i in 0..<schedule.schedules.count {
            schedule.schedules[i].isOpen = i % 2 == 0
            schedule.schedules[i].openTime = "18:00"
            schedule.schedules[i].closeTime = "02:00"
        }
        
        return Bar(
            name: "Test Bar \(Date().timeIntervalSince1970)",
            address: "123 Test Street",
            description: "A test bar with 7-day schedule",
            username: "testbar",
            password: "1234",
            weeklySchedule: schedule
        )
    }
    
    func testMigrationFromOldSchedule() {
        // Create a bar with old operating hours and test migration
        var oldHours = OperatingHours()
        oldHours.monday.isOpen = true
        oldHours.wednesday.isOpen = true
        oldHours.friday.isOpen = true
        
        let migratedSchedule = Bar.migrateOperatingHoursToWeeklySchedule(oldHours)
        print("🧪 Migration test: \(migratedSchedule.schedules.filter { $0.isOpen }.count) open days")
    }
}

extension DailySchedule {
    static func createTestSchedule(for date: Date, isOpen: Bool = true) -> DailySchedule {
        var schedule = DailySchedule(date: date)
        schedule.isOpen = isOpen
        schedule.openTime = "19:00"
        schedule.closeTime = "01:00"
        return schedule
    }
}
#endif

// MARK: - Validation Helpers

extension WeeklySchedule {
    // Add validation methods to ensure data integrity:
    
    var isValid: Bool {
        // Check if schedule has exactly 7 days
        guard schedules.count == 7 else { return false }
        
        // Check if dates are consecutive
        let sortedSchedules = schedules.sorted { $0.date < $1.date }
        for i in 1..<sortedSchedules.count {
            let daysBetween = Calendar.current.dateComponents([.day],
                from: sortedSchedules[i-1].date,
                to: sortedSchedules[i].date).day ?? 0
            if daysBetween != 1 {
                return false
            }
        }
        
        return true
    }
    
    func validateTimes() -> [String] {
        var errors: [String] = []
        
        for schedule in schedules {
            if schedule.isOpen {
                if !isValidTimeFormat(schedule.openTime) {
                    errors.append("Invalid open time for \(schedule.dayName): \(schedule.openTime)")
                }
                if !isValidTimeFormat(schedule.closeTime) {
                    errors.append("Invalid close time for \(schedule.dayName): \(schedule.closeTime)")
                }
            }
        }
        
        return errors
    }
    
    private func isValidTimeFormat(_ time: String) -> Bool {
        let timeRegex = "^([01]?[0-9]|2[0-3]):[0-5][0-9]$"
        return NSPredicate(format: "SELF MATCHES %@", timeRegex).evaluate(with: time)
    }
}
