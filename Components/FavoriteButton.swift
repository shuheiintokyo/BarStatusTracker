import SwiftUI

struct FavoriteButton: View {
    let barId: String
    @ObservedObject var barViewModel: BarViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var isAnimating = false
    @State private var showingNotificationAlert = false
    
    private var isFavorite: Bool {
        barViewModel.isFavorite(barId: barId)
    }
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Check if this is the first favorite and notifications not authorized
            if !isFavorite && !notificationManager.isAuthorized {
                showingNotificationAlert = true
            } else {
                toggleFavorite()
            }
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundColor(isFavorite ? .red : .gray)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Get Notified! 📱", isPresented: $showingNotificationAlert) {
            Button("Enable Notifications") {
                notificationManager.requestNotificationPermissions()
                toggleFavorite()
            }
            Button("Skip") {
                toggleFavorite()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get notified when this bar changes status! You can always change this in Settings later.")
        }
    }
    
    private func toggleFavorite() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isAnimating = true
        }
        
        barViewModel.toggleFavorite(barId: barId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isAnimating = false
            }
        }
    }
}

struct FloatingFavoriteButton: View {
    let barId: String
    @ObservedObject var barViewModel: BarViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var isAnimating = false
    @State private var showingNotificationAlert = false
    
    private var isFavorite: Bool {
        barViewModel.isFavorite(barId: barId)
    }
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Check if this is the first favorite and notifications not authorized
            if !isFavorite && !notificationManager.isAuthorized {
                showingNotificationAlert = true
            } else {
                toggleFavorite()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title)
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 10 : 0))
                
                Text(isFavorite ? "Favorited" : "Favorite")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(isFavorite ? Color.red : Color.gray)
                    .shadow(radius: isAnimating ? 8 : 4)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            )
        }
        .alert("Get Notified! 📱", isPresented: $showingNotificationAlert) {
            Button("Enable Notifications") {
                notificationManager.requestNotificationPermissions()
                toggleFavorite()
            }
            Button("Skip") {
                toggleFavorite()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get notified when this bar changes status! You can always change this in Settings later.")
        }
    }
    
    private func toggleFavorite() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isAnimating = true
        }
        
        barViewModel.toggleFavorite(barId: barId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isAnimating = false
            }
        }
    }
}

// Updated analytics view with real Firebase favorite counts
struct BarAnalyticsView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Favorites")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text("\(totalFavorites)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    // Show loading state if count is 0 but we're still loading
                    if totalFavorites == 0 && barViewModel.isLoading {
                        Text("Loading...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if totalFavorites == 0 {
                        Text("Be the first to like!")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text(totalFavorites == 1 ? "person likes this" : "people like this")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Last Update")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatLastUpdated(bar.lastUpdated))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // Show auto-transition info if active
            if bar.isAutoTransitionActive {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-transition active")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        if let pendingStatus = bar.pendingStatus {
                            Text("Will change to: \(pendingStatus.displayName)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let timeRemaining = barViewModel.getTimeRemainingText(for: bar) {
                        Text(timeRemaining)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Engagement metrics
            HStack {
                VStack(alignment: .leading) {
                    Text("Engagement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 2) {
                            Image(systemName: "eye.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Views")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text("\(totalFavorites) likes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var totalFavorites: Int {
        // Get real count from Firebase
        return barViewModel.getFavoriteCount(for: bar.id)
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Quick Stats View for Owner Dashboard
struct BarQuickStatsView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // Favorites Count
            VStack {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(barViewModel.getFavoriteCount(for: bar.id))")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text("Favorites")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // Status Indicator
            VStack {
                Image(systemName: bar.status.icon)
                    .font(.title2)
                    .foregroundColor(bar.status.color)
                Text(bar.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if bar.isAutoTransitionActive {
                Divider()
                    .frame(height: 40)
                
                // Timer Info
                VStack {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    if let timeRemaining = barViewModel.getTimeRemainingText(for: bar) {
                        Text(timeRemaining)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
