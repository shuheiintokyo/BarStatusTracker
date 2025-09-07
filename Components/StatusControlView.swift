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
            // Current Status Display with enhanced liquid glass
            currentStatusHeader
            
            // Today's Schedule Info with liquid glass
            todaysScheduleInfo
            
            // Auto-transition display (if active) with liquid glass
            if let current = currentBar, current.isAutoTransitionActive {
                autoTransitionCard
            }
            
            // 7-Day Schedule Management with liquid glass
            scheduleManagementSection
        }
        .liquidGlass(level: .regular, cornerRadius: .extraLarge, shadow: .prominent)
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
    
    // MARK: - Current Status Header with Enhanced Liquid Glass
    var currentStatusHeader: some View {
        VStack(spacing: 12) {
            LiquidGlassSectionHeader("Current Status")
            
            HStack(spacing: 16) {
                // Animated status indicator with liquid glass
                LiquidGlassStatusIndicator(
                    status: currentBar?.status ?? bar.status,
                    size: 70
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(currentBar?.status.displayName ?? bar.status.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentBar?.status.color ?? bar.status.color)
                    
                    Text("Last updated \(timeAgo(currentBar?.lastUpdated ?? bar.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Status source indicator
                    HStack(spacing: 4) {
                        Image(systemName: (currentBar?.isFollowingSchedule ?? bar.isFollowingSchedule) ? "calendar" : "hand.raised.fill")
                            .font(.caption)
                        Text((currentBar?.isFollowingSchedule ?? bar.isFollowingSchedule) ? "Following Schedule" : "Manual Override")
                            .font(.caption)
                    }
                    .foregroundColor((currentBar?.isFollowingSchedule ?? bar.isFollowingSchedule) ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        ((currentBar?.isFollowingSchedule ?? bar.isFollowingSchedule) ? Color.green : Color.orange).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                }
                
                Spacer()
            }
        }
        .liquidGlass(level: .thin, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Today's Schedule Info with Enhanced Liquid Glass
    var todaysScheduleInfo: some View {
        Group {
            if let current = currentBar, let todaysSchedule = current.todaysSchedule {
                VStack(spacing: 16) {
                    LiquidGlassSectionHeader("Today's Schedule")
                    
                    // Today's hours display with liquid glass
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today (\(todaysSchedule.dayName))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Text(todaysSchedule.displayDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
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
                            
                            Image(systemName: todaysSchedule.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(todaysSchedule.isOpen ? .green : .red)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(todaysSchedule.isOpen ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Manual override notification with liquid glass
                    if !current.isFollowingSchedule {
                        VStack(alignment: .leading, spacing: 8) {
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
                                .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .small))
                                .foregroundColor(.blue)
                            }
                            
                            Text("Current status (\(current.status.displayName)) differs from schedule (\(current.scheduleBasedStatus.displayName))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle, borderOpacity: 0.3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
            }
        }
    }
    
    // MARK: - Auto-transition Card with Enhanced Liquid Glass
    var autoTransitionCard: some View {
        VStack(spacing: 12) {
            HStack {
                LiquidGlassStatusIndicator(status: .closingSoon, size: 40) // Timer icon equivalent
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-change active")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if let pendingStatus = currentBar?.pendingStatus {
                        HStack(spacing: 4) {
                            Text("→")
                                .foregroundColor(.orange)
                                .font(.title3)
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
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .small))
                    .foregroundColor(.red)
                }
            }
        }
        .liquidGlass(level: .thin, cornerRadius: .large, shadow: .medium, borderOpacity: 0.3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - 7-Day Schedule Management Section with Enhanced Liquid Glass
    var scheduleManagementSection: some View {
        VStack(spacing: 16) {
            LiquidGlassSectionHeader(
                "7-Day Schedule",
                action: {
                    editingSchedule = currentBar?.weeklySchedule ?? bar.weeklySchedule
                    showingScheduleEditor = true
                },
                actionTitle: "Edit Schedule"
            )
            
            // Compact 7-day overview with liquid glass
            VStack(spacing: 8) {
                ForEach(currentBar?.weeklySchedule.schedules ?? bar.weeklySchedule.schedules) { schedule in
                    StatusScheduleRow(schedule: schedule)
                }
            }
            .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
            
            // Quick actions with enhanced liquid glass
            VStack(spacing: 12) {
                Text("Quick Actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    StatusQuickActionButton(
                        title: "Override: Open Now",
                        icon: "checkmark.circle.fill",
                        color: .green
                    ) {
                        barViewModel.setManualBarStatus(currentBar ?? bar, newStatus: .open)
                    }
                    
                    StatusQuickActionButton(
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
            .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
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

// MARK: - Status Schedule Row Component with Enhanced Liquid Glass (Renamed to avoid conflicts)
struct StatusScheduleRow: View {
    let schedule: DailySchedule
    
    var body: some View {
        HStack {
            // Day info with liquid glass styling
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
                            .background(.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                Text(schedule.displayDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            // Status with liquid glass styling
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
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            schedule.isToday ? .blue.opacity(0.05) : .clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(schedule.isToday ? .blue.opacity(0.2) : .clear, lineWidth: 1)
        )
    }
}

// MARK: - Status Quick Action Button Component with Enhanced Liquid Glass (Renamed to avoid conflicts)
struct StatusQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial)
                    .opacity(0.2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            action()
        }
    }
}

// MARK: - Schedule Editor View with Enhanced Liquid Glass
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
                    // Header with liquid glass
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit 7-Day Schedule")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Adjust your opening hours for each day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(level: .ultra, cornerRadius: .large, shadow: .subtle)
                    
                    // Schedule editors with liquid glass
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
                    
                    // Tips with liquid glass
                    VStack(alignment: .leading, spacing: 12) {
                        LiquidGlassSectionHeader("💡 Tips")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            StatusTipRow(text: "Changes take effect immediately")
                            StatusTipRow(text: "Today's schedule determines your current bar status")
                            StatusTipRow(text: "Drag the time sliders to adjust opening and closing times")
                            StatusTipRow(text: "Toggle off days when you're closed")
                        }
                    }
                    .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(.regularMaterial)
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
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Status Tip Row Component (Renamed to avoid conflicts)
struct StatusTipRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.blue.opacity(0.3))
                .frame(width: 4, height: 4)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
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
