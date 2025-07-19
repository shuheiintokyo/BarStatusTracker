import SwiftUI

struct StatusControlView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    // Get current bar state from view model to ensure real-time updates
    private var currentBar: Bar? {
        barViewModel.bars.first { $0.id == bar.id }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Status Display with Source Info
            currentStatusHeader
            
            // Schedule vs Manual Status Info - ENHANCED
            statusSourceInfo
            
            // Auto-transition display (if active)
            if let current = currentBar, current.isAutoTransitionActive {
                autoTransitionCard
            }
            
            // Status Control Grid
            statusControlGrid
            
            // Follow Schedule Button (if manual override is active)
            if let current = currentBar, !current.isFollowingSchedule {
                followScheduleButton
            }
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
    }
    
    // MARK: - Current Status Header (ENHANCED)
    var currentStatusHeader: some View {
        VStack(spacing: 8) {
            Text("Bar Status")
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
    
    // MARK: - Status Source Information (ENHANCED)
    var statusSourceInfo: some View {
        Group {
            if let current = currentBar {
                let statusInfo = current.statusDisplayInfo
                
                VStack(spacing: 12) {
                    // Main source info
                    HStack(spacing: 8) {
                        Image(systemName: current.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                            .foregroundColor(current.isFollowingSchedule ? .green : .orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(statusInfo.source)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(current.isFollowingSchedule ? .green : .orange)
                            
                            Text(statusInfo.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Show actual schedule status if manual override is active
                        if !current.isFollowingSchedule {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Schedule says:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: current.scheduleBasedStatus.icon)
                                        .font(.caption)
                                        .foregroundColor(current.scheduleBasedStatus.color)
                                    Text(current.scheduleBasedStatus.displayName)
                                        .font(.caption2)
                                        .foregroundColor(current.scheduleBasedStatus.color)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    
                    // Show today's operating hours for context
                    todaysHoursInfo(for: current)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(current.isFollowingSchedule ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(current.isFollowingSchedule ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Today's Hours Info (NEW)
    private func todaysHoursInfo(for bar: Bar) -> some View {
        let today = getCurrentWeekDay()
        let todayHours = bar.operatingHours.getDayHours(for: today)
        
        return VStack(spacing: 4) {
            HStack {
                Text("Today (\(today.displayName)):")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if todayHours.isOpen {
                    Text(todayHours.displayText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                } else {
                    Text("Closed")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
            
            // Show conflict warning if manual override conflicts with schedule
            if !bar.isFollowingSchedule && bar.status != bar.scheduleBasedStatus {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("Manual override active - differs from schedule")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Follow Schedule Button (ENHANCED)
    var followScheduleButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                barViewModel.setBarToFollowSchedule(currentBar ?? bar)
            }) {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.title3)
                    Text("Follow Schedule")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Preview what the status would be
                    if let current = currentBar {
                        HStack(spacing: 4) {
                            Text("→")
                                .foregroundColor(.white.opacity(0.7))
                            Image(systemName: current.scheduleBasedStatus.icon)
                                .font(.caption)
                            Text(current.scheduleBasedStatus.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Helpful text
            Text("This will change your status to match your operating hours schedule")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Auto-transition Card (existing)
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
    
    // MARK: - Status Control Grid (ENHANCED)
    var statusControlGrid: some View {
        VStack(spacing: 12) {
            Text("Change Status")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(BarStatus.allCases, id: \.self) { status in
                    StatusButton(
                        status: status,
                        currentStatus: currentBar?.status ?? bar.status,
                        scheduleStatus: currentBar?.scheduleBasedStatus ?? bar.scheduleBasedStatus,
                        isManualOverride: !(currentBar?.isFollowingSchedule ?? true),
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                barViewModel.setManualBarStatus(currentBar ?? bar, newStatus: status)
                            }
                        }
                    )
                }
            }
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
    
    private func getCurrentWeekDay() -> WeekDay {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        switch weekday {
        case 1: return WeekDay.sunday
        case 2: return WeekDay.monday
        case 3: return WeekDay.tuesday
        case 4: return WeekDay.wednesday
        case 5: return WeekDay.thursday
        case 6: return WeekDay.friday
        case 7: return WeekDay.saturday
        default: return WeekDay.monday
        }
    }
}

// MARK: - Enhanced Status Button
struct StatusButton: View {
    let status: BarStatus
    let currentStatus: BarStatus
    let scheduleStatus: BarStatus
    let isManualOverride: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var isSelected: Bool {
        status == currentStatus
    }
    
    private var isScheduleRecommended: Bool {
        status == scheduleStatus && !isSelected
    }
    
    private var buttonInfo: (title: String, subtitle: String, badge: String) {
        switch status {
        case .openingSoon:
            return ("Opening", "Soon", "15m")
        case .open:
            return ("Open", "Now", "")
        case .closingSoon:
            return ("Closing", "Soon", "15m")
        case .closed:
            return ("Closed", "Now", "")
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = false
                }
                action()
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 8) {
                // Icon with enhanced background
                ZStack {
                    Circle()
                        .fill(isSelected ? status.color : status.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.white.opacity(0.3) :
                                    isScheduleRecommended ? status.color.opacity(0.6) :
                                    status.color.opacity(0.3),
                                    lineWidth: isScheduleRecommended ? 3 : 2
                                )
                        )
                        .shadow(
                            color: isSelected ? status.color.opacity(0.4) : Color.clear,
                            radius: isSelected ? 8 : 0
                        )
                    
                    Image(systemName: status.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : status.color)
                        .fontWeight(isSelected ? .bold : .medium)
                    
                    // Manual override indicator
                    if isSelected && isManualOverride {
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Image(systemName: "hand.raised.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.white)
                                    )
                            }
                            Spacer()
                        }
                    }
                    
                    // Schedule recommendation indicator
                    if isScheduleRecommended {
                        VStack {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Image(systemName: "calendar")
                                            .font(.system(size: 6))
                                            .foregroundColor(.white)
                                    )
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                
                // Text info
                VStack(spacing: 2) {
                    Text(buttonInfo.title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? status.color : .primary)
                    
                    Text(buttonInfo.subtitle)
                        .font(.caption2)
                        .foregroundColor(isSelected ? status.color.opacity(0.8) : .secondary)
                    
                    if !buttonInfo.badge.isEmpty {
                        Text(buttonInfo.badge)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // Schedule recommendation text
                    if isScheduleRecommended {
                        Text("Schedule")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        status.color.opacity(0.15) :
                        isScheduleRecommended ?
                        status.color.opacity(0.08) :
                        Color.white.opacity(0.8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                status.color.opacity(0.6) :
                                isScheduleRecommended ?
                                status.color.opacity(0.4) :
                                Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : isScheduleRecommended ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? status.color.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 6 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
            .scaleEffect({
                let pressedScale = isPressed ? 0.95 : 1.0
                let selectedScale = isSelected ? 1.05 : 1.0
                let combinedScale = isPressed ? pressedScale : selectedScale
                return combinedScale.isFinite ? max(0.5, min(2.0, combinedScale)) : 1.0
            }())
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
