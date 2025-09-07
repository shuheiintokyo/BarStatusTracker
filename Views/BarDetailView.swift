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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with current status - Liquid Glass
                    headerSection
                    
                    Divider()
                        .background(.primary.opacity(0.2))
                    
                    // Owner quick controls (if applicable)
                    if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                        ownerControlsSection
                        Divider()
                            .background(.primary.opacity(0.2))
                    }
                    
                    // Schedule information
                    scheduleSection
                    
                    Divider()
                        .background(.primary.opacity(0.2))
                    
                    // About section
                    aboutSection
                    
                    Divider()
                        .background(.primary.opacity(0.2))
                    
                    // Social links
                    socialLinksSection
                    
                    // Owner settings (if applicable)
                    if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                        Divider()
                            .background(.primary.opacity(0.2))
                        ownerSettingsSection
                    }
                    
                    #if DEBUG
                    if showingDebugInfo {
                        Divider()
                            .background(.primary.opacity(0.2))
                        debugSection
                    }
                    #endif
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(.regularMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    #if DEBUG
                    Button("Debug") {
                        showingDebugInfo.toggle()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    #else
                    EmptyView()
                    #endif
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
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
    
    // MARK: - Header Section with Liquid Glass
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentBar.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    if let location = currentBar.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            Text(location.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .fontWeight(.medium)
                        }
                    } else if !currentBar.address.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Text(currentBar.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Large status indicator with Liquid Glass
                LiquidGlassStatusIndicator(status: currentBar.status, size: 80)
            }
            
            // Status information card with Liquid Glass
            statusInfoCard
        }
        .liquidGlass(level: .ultra, cornerRadius: .extraLarge, shadow: .medium)
    }
    
    var statusInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: currentBar.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                    .foregroundColor(currentBar.isFollowingSchedule ? .green : .orange)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentBar.isFollowingSchedule ? "Following Schedule" : "Manual Override")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(currentBar.isFollowingSchedule ?
                         "Status updates automatically based on schedule" :
                         "Owner has manually set the current status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("Updated \(timeAgo(currentBar.lastUpdated))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            // Show conflict warning if manual override differs from schedule
            if !currentBar.isFollowingSchedule && currentBar.status != currentBar.scheduleBasedStatus {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status Override Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text("Manual: \(currentBar.status.displayName) • Schedule: \(currentBar.scheduleBasedStatus.displayName)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Auto-transition info (if active)
            if currentBar.isAutoTransitionActive, let pendingStatus = currentBar.pendingStatus {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatic Change Scheduled")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        if let timeRemaining = barViewModel.getTimeRemainingText(for: currentBar) {
                            Text("Will change to \(pendingStatus.displayName) in \(timeRemaining)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
    }
    
    // MARK: - Owner Controls Section with Liquid Glass
    var ownerControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LiquidGlassSectionHeader("Quick Actions")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                if currentBar.status == .open {
                    DetailQuickActionButton(
                        title: "Close Now",
                        icon: "xmark.circle.fill",
                        color: .red
                    ) {
                        barViewModel.setManualBarStatus(currentBar, newStatus: .closed)
                    }
                } else {
                    DetailQuickActionButton(
                        title: "Open Now",
                        icon: "checkmark.circle.fill",
                        color: .green
                    ) {
                        barViewModel.setManualBarStatus(currentBar, newStatus: .open)
                    }
                }
                
                DetailQuickActionButton(
                    title: "Follow Schedule",
                    icon: "calendar",
                    color: .blue
                ) {
                    barViewModel.setBarToFollowSchedule(currentBar)
                }
                
                DetailQuickActionButton(
                    title: "Edit Schedule",
                    icon: "clock.badge.checkmark",
                    color: .purple
                ) {
                    editingWeeklySchedule = currentBar.weeklySchedule
                    showingEditWeeklySchedule = true
                }
                
                if currentBar.isAutoTransitionActive {
                    DetailQuickActionButton(
                        title: "Cancel Timer",
                        icon: "timer.square",
                        color: .orange
                    ) {
                        barViewModel.cancelAutoTransition(for: currentBar)
                    }
                }
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Schedule Section with Liquid Glass
    var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LiquidGlassSectionHeader(
                "Operating Hours",
                action: isOwnerMode && barViewModel.canEdit(bar: currentBar) ? {
                    editingWeeklySchedule = currentBar.weeklySchedule
                    showingEditWeeklySchedule = true
                } : nil,
                actionTitle: "Edit"
            )
            
            // Today's schedule (highlighted)
            if let todaysSchedule = currentBar.todaysSchedule {
                TodaysScheduleCard(schedule: todaysSchedule)
            }
            
            // This week overview
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    ForEach(currentBar.weeklySchedule.schedules) { schedule in
                        ScheduleRowCompact(schedule: schedule, isToday: schedule.isToday)
                    }
                }
                .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - About Section with Liquid Glass
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LiquidGlassSectionHeader(
                "About",
                action: isOwnerMode && barViewModel.canEdit(bar: currentBar) ? {
                    editingDescription = currentBar.description
                    showingEditDescription = true
                } : nil,
                actionTitle: "Edit"
            )
            
            if currentBar.description.isEmpty {
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    VStack(spacing: 8) {
                        Text("No description yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Add a description to tell customers about your bar")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("No description available.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(currentBar.description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Social Links Section with Liquid Glass
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LiquidGlassSectionHeader(
                "Connect",
                action: isOwnerMode && barViewModel.canEdit(bar: currentBar) ? {
                    editingSocialLinks = currentBar.socialLinks
                    showingEditSocialLinks = true
                } : nil,
                actionTitle: "Edit"
            )
            
            let hasAnyLinks = !currentBar.socialLinks.instagram.isEmpty ||
                             !currentBar.socialLinks.twitter.isEmpty ||
                             !currentBar.socialLinks.facebook.isEmpty ||
                             !currentBar.socialLinks.website.isEmpty
            
            if hasAnyLinks {
                SocialLinksView(socialLinks: currentBar.socialLinks)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                    VStack(spacing: 8) {
                        Text("No social links set up")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Add your social media links to help customers connect with you")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("No social links available")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Owner Settings Section with Liquid Glass
    var ownerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LiquidGlassSectionHeader("Account Settings")
            
            VStack(spacing: 12) {
                SettingsRow(
                    title: "Change Password",
                    subtitle: "Update your 4-digit login password",
                    icon: "key.fill",
                    color: .blue
                ) {
                    editingPassword = currentBar.password
                    showingEditPassword = true
                }
            }
            .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - DEBUG Section with Liquid Glass
    #if DEBUG
    var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔍 Debug Information")
                .font(.headline)
                .foregroundStyle(.primary)
            
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
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                
                // Full debug output
                Text(currentBar.debugScheduleStatus())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("No schedule available for debugging")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    private func debugInfoRow(_ label: String, _ value: String, color: Color? = nil) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color ?? .primary)
            
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

// MARK: - Supporting Components for BarDetailView with Liquid Glass

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
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
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
                            .foregroundColor(.blue)
                        
                        Text("(\(schedule.dayName))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(schedule.displayDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: schedule.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(schedule.isOpen ? .green : .red)
                    
                    Text(schedule.displayText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(schedule.isOpen ? .green : .red)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 2)
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
                        .foregroundColor(isToday ? .blue : .primary)
                    
                    if isToday {
                        Text("TODAY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                Text(schedule.displayDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Status
            HStack(spacing: 8) {
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
            isToday ? Color.blue.opacity(0.1) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? .blue.opacity(0.3) : .clear, lineWidth: 1)
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
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
    }
}
