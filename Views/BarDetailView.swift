import SwiftUI

struct BarDetailView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @Environment(\.dismiss) private var dismiss
    
    // Get the current bar state from the view model to ensure real-time updates
    private var currentBar: Bar {
        return barViewModel.bars.first { $0.id == bar.id } ?? bar
    }
    
    // Editing states - UPDATED for 7-day schedule
    @State private var editingDescription = ""
    @State private var showingEditDescription = false
    @State private var showingEditWeeklySchedule = false
    @State private var editingWeeklySchedule = WeeklySchedule()
    @State private var editingPassword = ""
    @State private var showingEditPassword = false
    
    // Social Links editing states
    @State private var editingSocialLinks = SocialLinks()
    @State private var showingEditSocialLinks = false
    
    // Debug state
    @State private var showingDebugInfo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // UPDATED: 7-Day Schedule Section (replaces Operating Hours)
                    scheduleSection
                    
                    Divider()
                    
                    // Description
                    descriptionSection
                    
                    Divider()
                    
                    // Social Links with editing capability
                    socialLinksSection
                    
                    // Owner Settings
                    if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                        Divider()
                        ownerSettingsSection
                    }
                    
                    // DEBUG INFO (in debug builds or for testing)
                    if showingDebugInfo {
                        Divider()
                        debugSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Debug toggle button (only show if needed)
                    Button("Debug") {
                        showingDebugInfo.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditDescription) {
            EditDescriptionView(description: $editingDescription) { newDescription in
                barViewModel.updateBarDescription(currentBar, newDescription: newDescription)
            }
        }
        .sheet(isPresented: $showingEditWeeklySchedule) {
            ScheduleEditorView(
                schedule: editingWeeklySchedule,
                barName: currentBar.name
            ) { newSchedule in
                barViewModel.updateBarSchedule(currentBar, newSchedule: newSchedule)
            }
        }
        .sheet(isPresented: $showingEditPassword) {
            EditPasswordView(
                currentPassword: currentBar.password,
                barName: currentBar.name
            ) { newPassword in
                barViewModel.updateBarPassword(currentBar, newPassword: newPassword)
            }
        }
        .sheet(isPresented: $showingEditSocialLinks) {
            EditSocialLinksView(
                socialLinks: $editingSocialLinks,
                barName: currentBar.name
            ) { newSocialLinks in
                barViewModel.updateBarSocialLinks(currentBar, newSocialLinks: newSocialLinks)
            }
        }
    }
    
    // MARK: - ENHANCED Header Section with Debug Info
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(currentBar.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Show location prominently if available
                    if let location = currentBar.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(location.displayName)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 2)
                        
                        if !currentBar.address.isEmpty && currentBar.address != location.city {
                            Text(currentBar.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(currentBar.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Current status display
                VStack {
                    Image(systemName: currentBar.status.icon)
                        .font(.system(size: 40))
                        .foregroundColor(currentBar.status.color)
                    
                    Text(currentBar.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(currentBar.status.color)
                }
            }
            
            // ENHANCED: Detailed status information with debugging
            let statusInfo = currentBar.statusDisplayInfo
            
            VStack(alignment: .leading, spacing: 8) {
                // Status source
                HStack(spacing: 8) {
                    Image(systemName: currentBar.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                        .foregroundColor(currentBar.isFollowingSchedule ? .green : .orange)
                        .font(.caption)
                    
                    Text(statusInfo.source)
                        .font(.caption)
                        .foregroundColor(currentBar.isFollowingSchedule ? .green : .orange)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Updated \(timeAgo(currentBar.lastUpdated))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Detailed description
                Text(statusInfo.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // CONFLICT WARNING: Show if manual override conflicts with schedule
                if statusInfo.isConflicting {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Status Override Active")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        
                        if let todaysSchedule = currentBar.todaysSchedule {
                            Text("Manual status (\(currentBar.status.displayName)) differs from schedule (\(currentBar.scheduleBasedStatus.displayName))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                                Button("Return to Schedule") {
                                    barViewModel.setBarToFollowSchedule(currentBar)
                                }
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 4)
            
            // Real-time auto-transition info (if active)
            if currentBar.isAutoTransitionActive, let pendingStatus = currentBar.pendingStatus {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("Will automatically change to \(pendingStatus.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let timeRemaining = barViewModel.getTimeRemainingText(for: currentBar) {
                            Text("Time remaining: \(timeRemaining)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Owner Controls
            if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                StatusControlView(bar: currentBar, barViewModel: barViewModel)
            }
        }
    }
    
    // MARK: - UPDATED: 7-Day Schedule Section
    var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("7-Day Schedule")
                    .font(.headline)
                
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    Spacer()
                    Button("Edit Schedule") {
                        editingWeeklySchedule = currentBar.weeklySchedule
                        showingEditWeeklySchedule = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Today's schedule (highlighted)
            if let todaysSchedule = currentBar.todaysSchedule {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack(spacing: 4) {
                                Text("Today")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text("(\(todaysSchedule.dayName))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Text(todaysSchedule.displayDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(todaysSchedule.displayText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(todaysSchedule.isOpen ? .green : .red)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(todaysSchedule.isOpen ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                )
            }
            
            // Next 6 days overview
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 6) {
                    ForEach(currentBar.weeklySchedule.schedules) { schedule in
                        ScheduleRowCompact(schedule: schedule, isToday: schedule.isToday)
                    }
                }
            }
        }
    }
    
    // MARK: - DEBUG Section
    var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔍 Debug Information")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let todaysSchedule = currentBar.todaysSchedule {
                let scheduleStatus = currentBar.scheduleBasedStatus
                let currentTime = Date()
                
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        debugInfoRow("Current Time", DateFormatter.localizedString(from: currentTime, dateStyle: .none, timeStyle: .medium))
                        debugInfoRow("Schedule", todaysSchedule.displayText)
                        debugInfoRow("Schedule Status", scheduleStatus.displayName, color: scheduleStatus.color)
                        debugInfoRow("Actual Status", currentBar.status.displayName, color: currentBar.status.color)
                        debugInfoRow("Following Schedule", currentBar.isFollowingSchedule ? "YES" : "NO", color: currentBar.isFollowingSchedule ? .green : .orange)
                        
                        if let manualStatus = currentBar.currentManualStatus {
                            debugInfoRow("Manual Override", manualStatus.displayName, color: .orange)
                        }
                        
                        if let openTime = parseTimeForDebug(todaysSchedule.openTime),
                           let closeTime = parseTimeForDebug(todaysSchedule.closeTime) {
                            let isOvernightSchedule = closeTime <= openTime
                            debugInfoRow("Overnight Schedule", isOvernightSchedule ? "YES" : "NO")
                            
                            if isOvernightSchedule {
                                let isCurrentlyOpen = currentTime >= openTime || currentTime < closeTime
                                debugInfoRow("Should Be Open (Overnight)", isCurrentlyOpen ? "YES" : "NO", color: isCurrentlyOpen ? .green : .red)
                            } else {
                                let isCurrentlyOpen = currentTime >= openTime && currentTime < closeTime
                                debugInfoRow("Should Be Open (Same Day)", isCurrentlyOpen ? "YES" : "NO", color: isCurrentlyOpen ? .green : .red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
                
                // Full debug output
                Text(currentBar.debugScheduleStatus())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("No schedule available for debugging")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Description Section
    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("About")
                    .font(.headline)
                
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    Spacer()
                    Button("Edit") {
                        editingDescription = currentBar.description
                        showingEditDescription = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Text(currentBar.description.isEmpty ? "No description available." : currentBar.description)
                .font(.body)
                .foregroundColor(currentBar.description.isEmpty ? .secondary : .primary)
        }
    }
    
    // MARK: - Social Links Section
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Social Links")
                    .font(.headline)
                
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    Spacer()
                    Button("Edit") {
                        editingSocialLinks = currentBar.socialLinks
                        showingEditSocialLinks = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if !currentBar.socialLinks.instagram.isEmpty ||
               !currentBar.socialLinks.twitter.isEmpty ||
               !currentBar.socialLinks.website.isEmpty ||
               !currentBar.socialLinks.facebook.isEmpty {
                
                SocialLinksView(socialLinks: currentBar.socialLinks)
            } else if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                VStack(spacing: 8) {
                    Text("No social links set up yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your social media profiles to help customers find you online")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            } else {
                Text("No social links available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Owner Settings Section
    var ownerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Owner Settings")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Login Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Current: ••••")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        editingPassword = currentBar.password
                        showingEditPassword = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helper Views and Functions
    
    private func debugInfoRow(_ label: String, _ value: String, color: Color? = nil) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color ?? .primary)
            
            Spacer()
        }
    }
    
    private func parseTimeForDebug(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(byAdding: timeComponents, to: today)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - UPDATED: Compact Schedule Row Component
struct ScheduleRowCompact: View {
    let schedule: DailySchedule
    let isToday: Bool
    
    var body: some View {
        HStack {
            // Day info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(schedule.shortDayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isToday ? .blue : .primary)
                    
                    Text(schedule.displayDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if isToday {
                        Text("TODAY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Schedule display
            HStack(spacing: 6) {
                Image(systemName: schedule.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(schedule.isOpen ? .green : .red)
                    .font(.caption)
                
                Text(schedule.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(schedule.isOpen ? .green : .red)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.blue.opacity(0.05) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
    }
}

#Preview {
    BarDetailView(
        bar: Bar(
            name: "Test Bar",
            address: "Test Address",
            username: "testbar",
            password: "1234"
        ),
        barViewModel: BarViewModel(),
        isOwnerMode: false
    )
}
