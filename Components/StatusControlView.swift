import SwiftUI

struct StatusControlView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    private var currentBar: Bar? {
        barViewModel.bars.first { $0.id == bar.id }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Status Display
            currentStatusHeader
            
            // Auto-transition display (if active)
            if let current = currentBar, current.isAutoTransitionActive {
                autoTransitionCard
            }
            
            // Status Control Grid
            statusControlGrid
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Current Status Header
    var currentStatusHeader: some View {
        VStack(spacing: 8) {
            Text("Bar Status")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                // Animated status icon
                ZStack {
                    Circle()
                        .fill(currentBar?.status.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: currentBar?.status.icon ?? "questionmark")
                        .font(.title)
                        .foregroundColor(currentBar?.status.color ?? .gray)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentBar?.status)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentBar?.status.displayName ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Last updated \(timeAgo(currentBar?.lastUpdated ?? Date()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Auto-transition Card
    var autoTransitionCard: some View {
        HStack(spacing: 12) {
            // Timer icon with animation
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
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
    
    // MARK: - Status Control Grid
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
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                barViewModel.updateBarStatus(currentBar ?? bar, newStatus: status)
                            }
                        }
                    )
                }
            }
        }
    }
    
    @State private var isAnimating = true
    
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

// MARK: - Enhanced Status Button
struct StatusButton: View {
    let status: BarStatus
    let currentStatus: BarStatus
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var isSelected: Bool {
        status == currentStatus
    }
    
    private var buttonInfo: (title: String, subtitle: String, duration: String) {
        switch status {
        case .openingSoon:
            return ("Opening", "Soon", "1m")
        case .open:
            return ("Open", "Now", "")
        case .closingSoon:
            return ("Closing", "Soon", "1m")
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
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 8) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(isSelected ? status.color : status.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: status.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : status.color)
                }
                
                // Text info
                VStack(spacing: 2) {
                    Text(buttonInfo.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(buttonInfo.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !buttonInfo.duration.isEmpty {
                        Text(buttonInfo.duration)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            .foregroundColor(isSelected ? status.color : .primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? status.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? status.color.opacity(0.5) : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
