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
                // Header with favorite/status indicator
                headerSection
                
                // Main content
                mainContentSection
                
                // Footer with quick info
                footerSection
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        HStack {
            // Status indicator dot
            Circle()
                .fill(bar.status.color)
                .frame(width: 8, height: 8)
                .opacity(0.8)
            
            Spacer()
            
            // Favorite button for guests
            if !isOwnerMode {
                FavoriteButton(barId: bar.id, barViewModel: barViewModel)
            } else {
                // Quick status indicator for owners
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
            
            // Bar name
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
    
    // MARK: - Footer Section
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
            } else if !isOwnerMode {
                // Show popularity for guests
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("\(barViewModel.getFavoriteCount(for: bar.id))")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white.opacity(0.8))
            } else {
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
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        bar.status.color,
                        bar.status.color.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: bar.status.color.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .overlay(
                // Subtle pattern overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
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

// MARK: - Compact Favorite Button
struct CompactFavoriteButton: View {
    let barId: String
    @ObservedObject var barViewModel: BarViewModel
    @State private var isAnimating = false
    
    private var isFavorite: Bool {
        barViewModel.isFavorite(barId: barId)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            
            barViewModel.toggleFavorite(barId: barId)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isAnimating = false
                }
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundColor(isFavorite ? .red : .white.opacity(0.7))
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .rotationEffect(.degrees(isAnimating ? 12 : 0))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
