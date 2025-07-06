import SwiftUI

struct StatusControlView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    // Get the current bar status from the view model to ensure real-time updates
    private var currentBar: Bar? {
        barViewModel.bars.first { $0.id == bar.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Update Status")
                .font(.headline)
            
            // Auto-transition status display (if active)
            if let current = currentBar, current.isAutoTransitionActive {
                AutoTransitionStatusView(bar: current, barViewModel: barViewModel)
            }
            
            // Status control buttons
            HStack(spacing: 10) {
                ForEach(BarStatus.allCases, id: \.self) { status in
                    StatusButton(
                        status: status,
                        currentStatus: currentBar?.status ?? bar.status,
                        action: {
                            barViewModel.updateBarStatus(currentBar ?? bar, newStatus: status)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Auto Transition Status View (Separate Component)
struct AutoTransitionStatusView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    private var timeRemainingText: String? {
        guard let timeRemaining = bar.timeUntilAutoTransition,
              timeRemaining > 0 else {
            return nil
        }
        
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                
                Text("Auto-Transition Active")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Cancel Timer") {
                    // Call the method that actually exists on BarViewModel
                    cancelAutoTransition()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current: \(bar.status.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let pendingStatus = bar.pendingStatus {
                        Text("Will change to: \(pendingStatus.displayName)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Time Remaining:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let timeRemaining = timeRemainingText {
                        Text(timeRemaining)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func cancelAutoTransition() {
        barViewModel.cancelAutoTransition(for: bar)
    }
}

struct StatusButton: View {
    let status: BarStatus
    let currentStatus: BarStatus
    let action: () -> Void
    
    private var isSelected: Bool {
        status == currentStatus
    }
    
    private var buttonText: String {
        switch status {
        case .openingSoon:
            return "Opening\nSoon (60m)"
        case .open:
            return "Open\nNow"
        case .closingSoon:
            return "Closing\nSoon (60m)"
        case .closed:
            return "Closed\nNow"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.title3)
                
                Text(buttonText)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? status.color : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
