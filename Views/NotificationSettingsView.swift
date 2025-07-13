import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if notificationManager.isAuthorized {
                    // ✅ Notifications enabled - show favorited bars
                    favoriteBarsList
                } else {
                    // ❌ No permission - show permission request
                    permissionRequestView
                }
            }
            .padding()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Permission Request View
    var permissionRequestView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("🍺 Bar Status Notifications")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get notified when your favorite bars change status!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                NotificationFeatureRow(
                    icon: "clock.badge.checkmark",
                    title: "Opening Soon",
                    description: "Know when bars are about to open"
                )
                
                NotificationFeatureRow(
                    icon: "checkmark.circle.fill",
                    title: "Now Open",
                    description: "Get alerted when bars open their doors"
                )
                
                NotificationFeatureRow(
                    icon: "clock.badge.exclamationmark",
                    title: "Closing Soon",
                    description: "Last call notifications"
                )
                
                NotificationFeatureRow(
                    icon: "xmark.circle.fill",
                    title: "Now Closed",
                    description: "Know when bars close for the night"
                )
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Button(action: {
                notificationManager.requestNotificationPermissions()
            }) {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("Enable Notifications")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            Button("Open Settings") {
                notificationManager.openNotificationSettings()
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    // MARK: - Favorite Bars List
    var favoriteBarsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("🔔 Notifications Enabled")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You'll receive notifications for bars you've favorited")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Show favorite bars
            let favoriteBarIds = barViewModel.userPreferencesManager.getFavoriteBarIds()
            let favoriteBars = barViewModel.getAllBars().filter { favoriteBarIds.contains($0.id) }
            
            if favoriteBars.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Favorite Bars Yet")
                        .font(.headline)
                    
                    Text("Heart your favorite bars to get notifications when their status changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Browse Bars") {
                        dismiss()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(favoriteBars) { bar in
                            FavoriteBarNotificationRow(bar: bar, barViewModel: barViewModel)
                        }
                    }
                }
                
                Text("💡 Tip: Add more bars to favorites by tapping the ❤️ icon on bar cards")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
    }
}

// MARK: - Helper Views

struct NotificationFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct FavoriteBarNotificationRow: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bar.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: bar.status.icon)
                        .foregroundColor(bar.status.color)
                    Text(bar.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}
