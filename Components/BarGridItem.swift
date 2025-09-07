import SwiftUI

struct BarGridItem: View {
    let bar: Bar
    let isOwnerMode: Bool
    @ObservedObject var barViewModel: BarViewModel
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    // Get current bar state with automatic schedule refresh
    private var currentBar: Bar {
        var foundBar = barViewModel.bars.first { $0.id == bar.id } ?? bar
        let _ = foundBar.refreshScheduleIfNeeded()
        return foundBar
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
                onTap()
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 0) {
                // Status indicator with Liquid Glass
                HStack {
                    Spacer()
                    LiquidGlassStatusIndicator(status: currentBar.status, size: 50)
                        .padding(.top)
                    Spacer()
                }
                
                // Bar information
                VStack(spacing: 8) {
                    // Bar name
                    Text(currentBar.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Schedule info with enhanced Liquid Glass styling
                    if let todaysSchedule = currentBar.todaysSchedule {
                        HStack(spacing: 4) {
                            Image(systemName: todaysSchedule.isOpen ? "calendar" : "moon")
                                .font(.caption2)
                                .foregroundColor(todaysSchedule.isOpen ? .green : .orange)
                            
                            Text(todaysSchedule.isOpen ? "Open today" : "Closed today")
                                .font(.caption2)
                                .foregroundColor(todaysSchedule.isOpen ? .green : .orange)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (todaysSchedule.isOpen ? Color.green : Color.orange).opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Text("No schedule")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }
                    
                    // Enhanced owner mode info
                    if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                        VStack(spacing: 4) {
                            if !currentBar.isFollowingSchedule {
                                HStack(spacing: 2) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Manual override")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            } else if let todaysSchedule = currentBar.todaysSchedule, todaysSchedule.isOpen {
                                Text(todaysSchedule.displayText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            // Auto-transition indicator
                            if currentBar.isAutoTransitionActive {
                                HStack(spacing: 2) {
                                    Image(systemName: "timer")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Text("Auto-change")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    
                    // Last updated info
                    Text("Updated \(timeAgo(currentBar.lastUpdated))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .liquidGlass(
            level: .regular,
            cornerRadius: .large,
            shadow: isPressed ? .subtle : .medium,
            borderOpacity: currentBar.isStatusConflictingWithSchedule ? 0.3 : 0.1
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        
        // Status conflict indicator for owner mode
        .overlay(
            Group {
                if isOwnerMode && barViewModel.canEdit(bar: currentBar) && currentBar.isStatusConflictingWithSchedule {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange, lineWidth: 2)
                        .opacity(0.7)
                }
            }
        )
    }
    
    // Helper function for time display
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

#Preview {
    BarGridItem(
        bar: Bar(
            name: "Test Bar",
            address: "123 Test St",
            username: "testbar",
            password: "1234"
        ),
        isOwnerMode: false,
        barViewModel: BarViewModel(),
        onTap: {}
    )
}
