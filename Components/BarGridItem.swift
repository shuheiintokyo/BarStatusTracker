import SwiftUI

struct BarGridItem: View {
    let bar: Bar
    let isOwnerMode: Bool
    @ObservedObject var barViewModel: BarViewModel
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    // Get current bar state from view model to ensure real-time updates
    private var currentBar: Bar {
        return barViewModel.bars.first { $0.id == bar.id } ?? bar
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
                // Card background - matches screenshot
                RoundedRectangle(cornerRadius: 16)
                    .fill(currentBar.status.color)
                    .frame(height: 140)
                
                VStack(spacing: 0) {
                    // Top section with indicators
                    HStack {
                        // UPDATED: Schedule/manual indicator (left side)
                        HStack(spacing: 4) {
                            Image(systemName: currentBar.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                            
                            if currentBar.isAutoTransitionActive {
                                Image(systemName: "timer")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // REMOVED: Red heart icon as requested
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    // Center content - Status icon (white circle with checkmark like screenshot)
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: currentBar.status.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Bottom section - Bar name, status, and schedule info
                    VStack(spacing: 4) {
                        Text(currentBar.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        
                        Text(currentBar.status.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        
                        // UPDATED: Schedule indicator instead of generic number
                        if let todaysSchedule = currentBar.todaysSchedule {
                            Text(todaysSchedule.isOpen ? "Open today" : "Closed today")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 2)
                        } else {
                            Text("No schedule")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 2)
                        }
                        
                        // UPDATED: Additional schedule context for owner mode
                        if isOwnerMode && barViewModel.canEdit(bar: currentBar) {
                            if !currentBar.isFollowingSchedule {
                                Text("Manual override")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.9))
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
                    }
                    .padding(.bottom, 16)
                }
            }
            .scaleEffect({
                let scale = isPressed ? 0.95 : 1.0
                return scale.isFinite ? max(0.5, min(2.0, scale)) : 1.0
            }())
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // UPDATED: Add subtle overlay for status conflicts (owner mode only)
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
}

// MARK: - Note: Supporting components moved to BarGridView.swift to avoid redeclaration

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
