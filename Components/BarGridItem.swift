import SwiftUI

struct BarGridItem: View {
    let bar: Bar
    let isOwnerMode: Bool
    @ObservedObject var barViewModel: BarViewModel
    let onTap: () -> Void
    
    @State private var isPressed = false
    
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
                // Header with status indicator
                headerSection
                
                // Main content
                mainContentSection
                
                // Footer with quick info
                footerSection
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .scaleEffect({
                let scale = isPressed ? 0.98 : 1.0
                return scale.isFinite ? max(0.5, min(2.0, scale)) : 1.0
            }())
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Header Section (Simplified)
    var headerSection: some View {
        HStack {
            // Status indicator dot
            Circle()
                .fill(bar.status.color)
                .frame(width: 8, height: 8)
                .opacity(0.8)
            
            Spacer()
            
            // Owner indicator for logged-in bars
            if isOwnerMode {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Text("OWNER")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Main Content Section
    var mainContentSection: some View {
        VStack(spacing: 12) {
            // Status icon with animation
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: bar.status.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.3), value: bar.status)
            }
            
            // Bar name and status
            VStack(spacing: 4) {
                Text(bar.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(bar.status.displayName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 12)
    }
    
    // MARK: - Footer Section (Simplified)
    var footerSection: some View {
        VStack(spacing: 4) {
            // Auto-transition indicator
            if bar.isAutoTransitionActive, let pendingStatus = bar.pendingStatus {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text("→ \(pendingStatus.displayName)")
                        .font(.caption2)
                        .lineLimit(1)
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.2))
                .cornerRadius(6)
            } else if bar.location != nil {
                // Show location for context
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(bar.location?.city ?? "")
                        .font(.caption2)
                        .lineLimit(1)
                }
                .foregroundColor(.white.opacity(0.8))
            } else if isOwnerMode {
                // Show last updated for owners
                Text("Updated \(timeAgo(bar.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Card Background
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(bar.status.color)
            .shadow(
                color: bar.status.color.opacity(0.3),
                radius: 6,
                x: 0,
                y: 3
            )
            .overlay(
                // Subtle highlight overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        Color.white.opacity(0.1)
                    )
                    .blendMode(.overlay)
            )
    }
    
    // MARK: - Helper Functions
    
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
