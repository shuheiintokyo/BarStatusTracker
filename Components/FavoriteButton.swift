import SwiftUI

struct FavoriteButton: View {
    let barId: String
    @ObservedObject var barViewModel: BarViewModel
    
    private var isFavorite: Bool {
        barViewModel.userPreferencesManager.isFavorite(barId: barId)
    }
    
    var body: some View {
        Button(action: {
            // Use BarViewModel's method which updates both local and Firebase
            barViewModel.toggleFavorite(barId: barId)
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundColor(isFavorite ? .red : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FloatingFavoriteButton: View {
    let barId: String
    @ObservedObject var barViewModel: BarViewModel
    
    private var isFavorite: Bool {
        barViewModel.userPreferencesManager.isFavorite(barId: barId)
    }
    
    var body: some View {
        Button(action: {
            barViewModel.toggleFavorite(barId: barId)
        }) {
            VStack(spacing: 4) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text(isFavorite ? "Favorited" : "Favorite")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(isFavorite ? Color.red : Color.gray)
                    .shadow(radius: 4)
            )
        }
    }
}

// Updated analytics view with Firebase favorite counts
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
                    
                    Text("\(totalFavorites)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
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
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var totalFavorites: Int {
        // Get total favorites from Firebase
        return barViewModel.getFavoriteCount(for: bar.id)
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
