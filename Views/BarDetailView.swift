import SwiftUI

struct BarDetailView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @Environment(\.dismiss) private var dismiss
    
    // Get current bar state for real-time updates
    private var currentBar: Bar {
        return barViewModel.bars.first { $0.id == bar.id } ?? bar
    }
    
    // Editing states
    @State private var editingDescription = ""
    @State private var showingEditDescription = false
    @State private var showingEditWeeklySchedule = false
    @State private var editingWeeklySchedule = WeeklySchedule()
    @State private var editingPassword = ""
    @State private var showingEditPassword = false
    @State private var editingSocialLinks = SocialLinks()
    @State private var showingEditSocialLinks = false
    
    #if DEBUG
    @State private var showingDebugInfo = false
    #endif
    
    var body: some View {
        NavigationView {
            // Using backgroundimg01 for bar detail
            StylishBackgroundView(
                imageName: "backgroundimg01",
                opacity: 0.35,
                blurRadius: 2.0
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with current status - glass effect
                        headerSection
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Owner quick controls (if applicable)
                        if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                            ownerControlsSection
                            Divider()
                                .background(Color.white.opacity(0.3))
                        }
                        
                        // Schedule information
                        scheduleSection
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // About section
                        aboutSection
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Social links
                        socialLinksSection
                        
                        // Owner settings (if applicable)
                        if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                            Divider()
                                .background(Color.white.opacity(0.3))
                            ownerSettingsSection
                        }
                        
                        #if DEBUG
                        if showingDebugInfo {
                            Divider()
                                .background(Color.white.opacity(0.3))
                            debugSection
                        }
                        #endif
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    #if DEBUG
                    Button("Debug") {
                        showingDebugInfo.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    #else
                    EmptyView()
                    #endif
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
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
    
    // MARK: - Header Section with Glass Effect
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentBar.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let location = currentBar.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Text(location.displayName)
                                .font(.headline)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                    } else if !currentBar.address.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                            Text(currentBar.address)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Large status indicator with glass effect
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: currentBar.status.icon)
                            .font(.system(size: 32))
                            .foregroundColor(currentBar.status.color)
                    }
                    
                    Text(currentBar.status.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Status information card with glass effect
            statusInfoCard
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8)
        )
    }
    
    var statusInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: currentBar.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                    .foregroundColor(currentBar.isFollowingSchedule ? Color.green : Color.orange)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentBar.isFollowingSchedule ? "Following Schedule" : "Manual Override")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(currentBar.isFollowingSchedule ?
                         "Status updates automatically based on schedule" :
                         "Owner has manually set the current status")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("Updated \(timeAgo(currentBar.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Show conflict warning if manual override differs from schedule
            if !currentBar.isFollowingSchedule && currentBar.status != currentBar.scheduleBasedStatus {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status Override Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Manual: \(currentBar.status.displayName) • Schedule: \(currentBar.scheduleBasedStatus.displayName)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            
            // Auto-transition info (if active)
            if currentBar.isAutoTransitionActive, let pendingStatus = currentBar.pendingStatus {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(Color.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatic Change Scheduled")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if let timeRemaining = barViewModel.getTimeRemainingText(for: currentBar) {
                            Text("Will change to \(pendingStatus.displayName) in \(timeRemaining)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                        )
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
        )
    }
    
    // MARK: - Owner Controls Section with Glass Effect
    var ownerControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                if currentBar.status == .open {
                    DetailQuickActionButton(
                        title: "Close Now",
                        icon: "xmark.circle.fill",
                        color: Color.red
                    ) {
                        barViewModel.setManualBarStatus(currentBar, newStatus: .closed)
                    }
                } else {
                    DetailQuickActionButton(
                        title: "Open Now",
                        icon: "checkmark.circle.fill",
                        color: Color.green
                    ) {
                        barViewModel.setManualBarStatus(currentBar, newStatus: .open)
                    }
                }
                
                DetailQuickActionButton(
                    title: "Follow Schedule",
                    icon: "calendar",
                    color: Color.blue
                ) {
                    barViewModel.setBarToFollowSchedule(currentBar)
                }
                
                DetailQuickActionButton(
                    title: "Edit Schedule",
                    icon: "clock.badge.checkmark",
                    color: Color.purple
                ) {
                    editingWeeklySchedule = currentBar.weeklySchedule
                    showingEditWeeklySchedule = true
                }
                
                if currentBar.isAutoTransitionActive {
                    DetailQuickActionButton(
                        title: "Cancel Timer",
                        icon: "timer.square",
                        color: Color.orange
                    ) {
                        barViewModel.cancelAutoTransition(for: currentBar)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Schedule Section with Glass Effect
    var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Operating Hours")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    Spacer()
                    Button("Edit") {
                        editingWeeklySchedule = currentBar.weeklySchedule
                        showingEditWeeklySchedule = true
                    }
                    .font(.caption)
                    .foregroundColor(Color.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    )
                }
            }
            
            // Today's schedule (highlighted)
            if let todaysSchedule = currentBar.todaysSchedule {
                TodaysScheduleCard(schedule: todaysSchedule)
            }
            
            // This week overview
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                VStack(spacing: 8) {
                    ForEach(currentBar.weeklySchedule.schedules) { schedule in
                        ScheduleRowCompact(schedule: schedule, isToday: schedule.isToday)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - About Section with Glass Effect
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("About")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    Spacer()
                    Button("Edit") {
                        editingDescription = currentBar.description
                        showingEditDescription = true
                    }
                    .font(.caption)
                    .foregroundColor(Color.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    )
                }
            }
            
            if currentBar.description.isEmpty {
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    VStack(spacing: 8) {
                        Text("No description yet")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Add a description to tell customers about your bar")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    )
                } else {
                    Text("No description available.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Text(currentBar.description)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Social Links Section with Glass Effect
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connect")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    Spacer()
                    Button("Edit") {
                        editingSocialLinks = currentBar.socialLinks
                        showingEditSocialLinks = true
                    }
                    .font(.caption)
                    .foregroundColor(Color.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    )
                }
            }
            
            let hasAnyLinks = !currentBar.socialLinks.instagram.isEmpty ||
                             !currentBar.socialLinks.twitter.isEmpty ||
                             !currentBar.socialLinks.facebook.isEmpty ||
                             !currentBar.socialLinks.website.isEmpty
            
            if hasAnyLinks {
                SocialLinksView(socialLinks: currentBar.socialLinks)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                    )
            } else {
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    VStack(spacing: 8) {
                        Text("No social links set up")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Add your social media links to help customers connect with you")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    )
                } else {
                    Text("No social links available")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Owner Settings Section with Glass Effect
    var ownerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SettingsRow(
                    title: "Change Password",
                    subtitle: "Update your 4-digit login password",
                    icon: "key.fill",
                    color: Color.blue
                ) {
                    editingPassword = currentBar.password
                    showingEditPassword = true
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - DEBUG Section (Only in Debug Builds) with Glass Effect
    #if DEBUG
    var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔍 Debug Information")
                .font(.headline)
                .foregroundColor(.white)
            
            if let todaysSchedule = currentBar.todaysSchedule {
                let scheduleStatus = currentBar.scheduleBasedStatus
                let currentTime = Date()
                
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        debugInfoRow("Current Time", DateFormatter.localizedString(from: currentTime, dateStyle: .none, timeStyle: .medium))
                        debugInfoRow("Schedule", todaysSchedule.displayText)
                        debugInfoRow("Schedule Status", scheduleStatus.displayName, color: scheduleStatus.color)
                        debugInfoRow("Actual Status", currentBar.status.displayName, color: currentBar.status.color)
                        debugInfoRow("Following Schedule", currentBar.isFollowingSchedule ? "YES" : "NO", color: currentBar.isFollowingSchedule ? Color.green : Color.orange)
                        
                        if let manualStatus = currentBar.currentManualStatus {
                            debugInfoRow("Manual Override", manualStatus.displayName, color: Color.orange)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.thinMaterial)
                )
                
                // Full debug output
                Text(currentBar.debugScheduleStatus())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
            } else {
                Text("No schedule available for debugging")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
    
    private func debugInfoRow(_ label: String, _ value: String, color: Color? = nil) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color ?? .white)
            
            Spacer()
        }
    }
    #endif
    
    // MARK: - Helper Functions
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
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

// MARK: - Missing Supporting Components for BarDetailView

struct DetailQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TodaysScheduleCard: View {
    let schedule: DailySchedule
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Today")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.blue)
                        
                        Text("(\(schedule.dayName))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Text(schedule.displayDate)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: schedule.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(schedule.isOpen ? Color.green : Color.red)
                    
                    Text(schedule.displayText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(schedule.isOpen ? Color.green : Color.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

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
                        .foregroundColor(isToday ? Color.blue : .white)
                    
                    if isToday {
                        Text("TODAY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(schedule.displayDate)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Status
            HStack(spacing: 8) {
                Image(systemName: schedule.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(schedule.isOpen ? Color.green : Color.red)
                    .font(.caption)
                
                Text(schedule.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(schedule.isOpen ? Color.green : Color.red)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.blue.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
