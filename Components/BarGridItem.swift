import SwiftUI

struct BarGridItem: View {
    let bar: Bar
    let isOwnerMode: Bool
    @ObservedObject var userPreferencesManager: UserPreferencesManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Header with favorite button
                HStack {
                    Spacer()
                    
                    if !isOwnerMode {
                        FavoriteButton(barId: bar.id, userPreferencesManager: userPreferencesManager)
                    }
                }
                .frame(height: 20)
                
                // Status Icon
                Image(systemName: bar.status.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                
                // Bar Name
                Text(bar.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Status Text with timer info
                VStack(spacing: 2) {
                    Text(bar.status.displayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Show timer info if active
                    if bar.isAutoTransitionActive, let pendingStatus = bar.pendingStatus {
                        Text("→ \(pendingStatus.displayName)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Last Updated (for owners)
                if isOwnerMode {
                    Text("Updated: \(formatTime(bar.lastUpdated))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(bar.status.color.gradient)
                    .shadow(radius: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
