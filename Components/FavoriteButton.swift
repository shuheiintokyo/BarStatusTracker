import SwiftUI

struct FavoriteButton: View {
    let barId: String
    @ObservedObject var userPreferencesManager: UserPreferencesManager
    
    private var isFavorite: Bool {
        userPreferencesManager.isFavorite(barId: barId)
    }
    
    var body: some View {
        Button(action: {
            userPreferencesManager.toggleFavorite(barId: barId)
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundColor(isFavorite ? .red : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Simplified floating favorite button
struct FloatingFavoriteButton: View {
    let barId: String
    @ObservedObject var userPreferencesManager: UserPreferencesManager
    
    private var isFavorite: Bool {
        userPreferencesManager.isFavorite(barId: barId)
    }
    
    var body: some View {
        Button(action: {
            userPreferencesManager.toggleFavorite(barId: barId)
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

// Simple analytics view placeholder
struct BarAnalyticsView: View {
    let bar: Bar
    @ObservedObject var userPreferencesManager: UserPreferencesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(followersCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Last Update")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Recently")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    
    private var followersCount: Int {
        return userPreferencesManager.isFavorite(barId: bar.id) ? 1 : 0
    }
}
