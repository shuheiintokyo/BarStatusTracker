import SwiftUI

struct BarGridItem: View {
    let bar: Bar
    let isOwnerMode: Bool
    @ObservedObject var barViewModel: BarViewModel
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    // FIXED: Get current bar state with automatic schedule refresh
    private var currentBar: Bar {
        var foundBar = barViewModel.bars.first { $0.id == bar.id } ?? bar
        // Always refresh schedule when displaying to ensure current info
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
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 16)
                    .fill(currentBar.status.color)
                    .frame(height: 140)
                
                VStack(spacing: 0) {
                    
                    // Bottom section - Bar name, status, and schedule info
                    VStack(spacing: 4) {
                        Text(currentBar.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        
                        // FIXED: Always show current, refreshed schedule info
                        if let todaysSchedule = currentBar.todaysSchedule {
                            HStack(spacing: 4) {
                                Image(systemName: todaysSchedule.isOpen ? "calendar" : "moon")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(todaysSchedule.isOpen ? "Open today" : "Closed today")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 2)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("No schedule")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.top, 2)
                        }
                        
                        // FIXED: Enhanced schedule context for owner mode
                        if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                            if !currentBar.isFollowingSchedule {
                                HStack(spacing: 2) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Text("Manual override")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(4)
                            } else if let todaysSchedule = currentBar.todaysSchedule, todaysSchedule.isOpen {
                                Text(todaysSchedule.displayText)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }
                        
                        // FIXED: Show last updated time for debugging
                        #if DEBUG
                        Text("Updated: \(timeAgo(currentBar.lastUpdated))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        #endif
                    }
                    .padding(.bottom, 16)
                }
            }
            .scaleEffect({
                let scale = isPressed ? 0.95 : 1.0
                return scale.isFinite ? max(0.5, min(2.0, scale)) : 1.0
            }())
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // FIXED: Add subtle overlay for status conflicts (owner mode only)
            .overlay(
                Group {
                    if isOwnerMode && barViewModel.canEdit(bar: currentBar) && currentBar.isStatusConflictingWithSchedule {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange, lineWidth: 2)
                            .opacity(0.7)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // FIXED: Helper function for time display
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
