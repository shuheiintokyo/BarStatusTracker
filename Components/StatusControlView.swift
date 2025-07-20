import SwiftUI

struct StatusControlView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    // Get current bar state from view model to ensure real-time updates
    private var currentBar: Bar? {
        barViewModel.bars.first { $0.id == bar.id }
    }
    
    @State private var editingSchedule: WeeklySchedule?
    @State private var showingScheduleEditor = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Status Display
            currentStatusHeader
            
            // Today's Schedule Info
            todaysScheduleInfo
            
            // Auto-transition display (if active)
            if let current = currentBar, current.isAutoTransitionActive {
                autoTransitionCard
            }
            
            // 7-Day Schedule Management
            scheduleManagementSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingScheduleEditor) {
            if let editingSchedule = editingSchedule {
                ScheduleEditorView(
                    schedule: editingSchedule,
                    barName: currentBar?.name ?? bar.name
                ) { newSchedule in
                    barViewModel.updateBarSchedule(currentBar ?? bar, newSchedule: newSchedule)
                }
            }
        }
    }
    
    // MARK: - Current Status Header
    var currentStatusHeader: some View {
        VStack(spacing: 8) {
            Text("Current Status")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                // Animated status icon with current status color
                ZStack {
                    Circle()
                        .fill((currentBar?.status.color ?? Color.gray).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: currentBar?.status.icon ?? "questionmark")
                        .font(.title)
                        .foregroundColor(currentBar?.status.color ?? .gray)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentBar?.status)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentBar?.status.displayName ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentBar?.status.color ?? .gray)
                    
                    Text("Last updated \(timeAgo(currentBar?.lastUpdated ?? Date()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Today's Schedule Info
    var todaysScheduleInfo: some View {
        Group {
            if let current = currentBar, let todaysSchedule = current.todaysSchedule {
                VStack(spacing: 12) {
                    HStack {
                        Text("Today's Schedule")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Status source indicator
                        HStack(spacing: 4) {
                            Image(systemName: current.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                                .foregroundColor(current.isFollowingSchedule ? .green : .orange)
                                .font(.caption)
                            
                            Text(current.isFollowingSchedule ? "Following Schedule" : "Manual Override")
                                .font(.caption)
                                .foregroundColor(current.isFollowingSchedule ? .green : .orange)
                        }
                    }
                    
                    // Today's hours display
                    HStack {
                        Text("Today (\(todaysSchedule.dayName)):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if todaysSchedule.isOpen {
                            Text(todaysSchedule.displayText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        } else {
                            Text("Closed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(todaysSchedule.isOpen ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(todaysSchedule.isOpen ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Manual override notification
                    if !current.isFollowingSchedule {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Manual Override Active")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                                
                                Button("Return to Schedule") {
                                    barViewModel.setBarToFollowSchedule(current)
                                }
                                .font(.caption2)
                                .foregroundColor(.blue)
                            }
                            
                            Text("Current status (\(current.status.displayName)) differs from schedule (\(current.scheduleBasedStatus.displayName))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Auto-transition Card (keep existing)
    var autoTransitionCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Auto-change active")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let pendingStatus = currentBar?.pendingStatus {
                    HStack(spacing: 4) {
                        Text("→")
                            .foregroundColor(.orange)
                        Text(pendingStatus.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let timeRemaining = barViewModel.getTimeRemainingText(for: currentBar ?? bar) {
                    Text(timeRemaining)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .monospacedDigit()
                }
                
                Button("Cancel") {
                    barViewModel.cancelAutoTransition(for: currentBar ?? bar)
                }
                .font(.caption2)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 7-Day Schedule Management Section
    var scheduleManagementSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("7-Day Schedule")
                    .font(.headline)
                
                Spacer()
                
                Button("Edit Schedule") {
                    editingSchedule = currentBar?.weeklySchedule ?? bar.weeklySchedule
                    showingScheduleEditor = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Compact 7-day overview
            VStack(spacing: 8) {
                ForEach(currentBar?.weeklySchedule.schedules ?? bar.weeklySchedule.schedules) { schedule in
                    ScheduleRow(schedule: schedule)
                }
            }
            
            // Quick actions
            VStack(spacing: 8) {
                Text("Quick Actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "Override: Open Now",
                        icon: "checkmark.circle.fill",
                        color: .green
                    ) {
                        barViewModel.setManualBarStatus(currentBar ?? bar, newStatus: .open)
                    }
                    
                    QuickActionButton(
                        title: "Override: Closed Now",
                        icon: "xmark.circle.fill",
                        color: .red
                    ) {
                        barViewModel.setManualBarStatus(currentBar ?? bar, newStatus: .closed)
                    }
                }
                
                Text("These override your schedule temporarily")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Functions
    
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

// MARK: - Schedule Row Component
struct ScheduleRow: View {
    let schedule: DailySchedule
    
    var body: some View {
        HStack {
            // Day info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(schedule.shortDayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(schedule.isToday ? .blue : .primary)
                    
                    if schedule.isToday {
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
                
                Text(schedule.displayDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
            RoundedRectangle(cornerRadius: 8)
                .fill(schedule.isToday ? Color.blue.opacity(0.05) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(schedule.isToday ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Action Button Component
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(8)
        }
    }
}

// MARK: - Schedule Editor View
struct ScheduleEditorView: View {
    @State private var schedule: WeeklySchedule
    let barName: String
    let onSave: (WeeklySchedule) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(schedule: WeeklySchedule, barName: String, onSave: @escaping (WeeklySchedule) -> Void) {
        self._schedule = State(initialValue: schedule)
        self.barName = barName
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit 7-Day Schedule")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Adjust your opening hours for each day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Schedule editors
                    VStack(spacing: 16) {
                        ForEach(Array(schedule.schedules.enumerated()), id: \.element.id) { index, dailySchedule in
                            DailyScheduleEditor(
                                schedule: Binding(
                                    get: { schedule.schedules[index] },
                                    set: { schedule.schedules[index] = $0 }
                                )
                            )
                        }
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Tips")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Changes take effect immediately")
                            Text("• Today's schedule determines your current bar status")
                            Text("• Drag the time sliders to adjust opening and closing times")
                            Text("• Toggle off days when you're closed")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Schedule for \(barName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(schedule)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StatusControlView(bar: Bar(
        name: "Test Bar",
        address: "Test Address",
        username: "testbar",
        password: "1234"
    ), barViewModel: BarViewModel())
}
