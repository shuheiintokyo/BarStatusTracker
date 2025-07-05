import SwiftUI

struct BarDetailView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var editingDescription = ""
    @State private var showingEditDescription = false
    @State private var showingDetailedAnalytics = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(bar.name)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    
                                    Text(bar.address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: bar.status.icon)
                                        .font(.system(size: 40))
                                        .foregroundColor(bar.status.color)
                                    
                                    Text(bar.status.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            // Real-time auto-transition info (if active)
                            if bar.isAutoTransitionActive, let pendingStatus = bar.pendingStatus {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Will automatically change to \(pendingStatus.displayName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if let timeRemaining = barViewModel.getTimeRemainingText(for: bar) {
                                            Text("Time remaining: \(timeRemaining)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            // Owner Controls
                            if isOwnerMode {
                                StatusControlView(bar: bar, barViewModel: barViewModel)
                            }
                        }
                        
                        Divider()
                        
                        // Quick Stats (for both owners and guests)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Bar Stats")
                                    .font(.headline)
                                
                                Spacer()
                                
                                // Real-time favorite count for everyone
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    
                                    Text("\(barViewModel.getFavoriteCount(for: bar.id))")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                    
                                    Text(barViewModel.getFavoriteCount(for: bar.id) == 1 ? "like" : "likes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !isOwnerMode {
                                // Guest view of favorites
                                HStack {
                                    Image(systemName: barViewModel.isFavorite(barId: bar.id) ? "heart.fill" : "heart")
                                        .foregroundColor(barViewModel.isFavorite(barId: bar.id) ? .red : .gray)
                                    
                                    if barViewModel.isFavorite(barId: bar.id) {
                                        Text("You have favorited this bar")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Tap the heart to add to favorites and get notifications")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Description
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("About")
                                    .font(.headline)
                                
                                if isOwnerMode {
                                    Spacer()
                                    Button("Edit") {
                                        editingDescription = bar.description
                                        showingEditDescription = true
                                    }
                                    .font(.caption)
                                }
                            }
                            
                            Text(bar.description.isEmpty ? "No description available." : bar.description)
                                .font(.body)
                                .foregroundColor(bar.description.isEmpty ? .secondary : .primary)
                        }
                        
                        // Social Links
                        if !bar.socialLinks.instagram.isEmpty || !bar.socialLinks.twitter.isEmpty || !bar.socialLinks.website.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Follow Us")
                                    .font(.headline)
                                
                                SocialLinksView(socialLinks: bar.socialLinks)
                            }
                        }
                        
                        // Enhanced Analytics for bar owners
                        if isOwnerMode {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("Analytics Dashboard")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button("View Details") {
                                        showingDetailedAnalytics = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                
                                BarQuickStatsView(bar: bar, barViewModel: barViewModel)
                                
                                BarAnalyticsView(bar: bar, barViewModel: barViewModel)
                                
                                // Additional owner insights
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Owner Insights")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Total Favorites")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("\(barViewModel.getFavoriteCount(for: bar.id))")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.red)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("Your Bar Status")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(bar.status.displayName)
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(bar.status.color)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(10)
                            }
                        }
                        
                        Spacer(minLength: 100) // Space for floating button
                    }
                    .padding()
                }
                
                // Floating favorite button (for non-owners)
                if !isOwnerMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingFavoriteButton(
                                barId: bar.id,
                                barViewModel: barViewModel
                            )
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                // Debug button for development (can be removed in production)
                if isOwnerMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Debug") {
                            barViewModel.debugFavorites()
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditDescription) {
            EditDescriptionView(description: $editingDescription) { newDescription in
                barViewModel.updateBarDescription(bar, newDescription: newDescription)
            }
        }
        .sheet(isPresented: $showingDetailedAnalytics) {
            DetailedAnalyticsView(bar: bar, barViewModel: barViewModel)
        }
    }
}

// Detailed Analytics View for Bar Owners
struct DetailedAnalyticsView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(bar.name) Analytics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Detailed insights for your bar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Key Metrics
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Key Metrics")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            MetricCard(
                                title: "Total Favorites",
                                value: "\(barViewModel.getFavoriteCount(for: bar.id))",
                                icon: "heart.fill",
                                color: .red
                            )
                            
                            MetricCard(
                                title: "Current Status",
                                value: bar.status.displayName,
                                icon: bar.status.icon,
                                color: bar.status.color
                            )
                            
                            MetricCard(
                                title: "Last Updated",
                                value: formatTime(bar.lastUpdated),
                                icon: "clock.fill",
                                color: .blue
                            )
                            
                            MetricCard(
                                title: "Auto-Timer",
                                value: bar.isAutoTransitionActive ? "Active" : "Inactive",
                                icon: "timer",
                                color: bar.isAutoTransitionActive ? .orange : .gray
                            )
                        }
                    }
                    
                    // Real-time Info
                    if bar.isAutoTransitionActive {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Auto-Transition Status")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Will change to: \(bar.pendingStatus?.displayName ?? "Unknown")")
                                        .font(.subheadline)
                                }
                                
                                if let timeRemaining = barViewModel.getTimeRemainingText(for: bar) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.orange)
                                        Text("Time remaining: \(timeRemaining)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    // User Engagement
                    VStack(alignment: .leading, spacing: 10) {
                        Text("User Engagement")
                            .font(.headline)
                        
                        Text("People who have favorited your bar will receive notifications when you update your status.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            Text("\(barViewModel.getFavoriteCount(for: bar.id)) users will be notified of status changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Tips for Bar Owners
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tips to Increase Engagement")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(icon: "pencil", text: "Keep your description updated with current offerings")
                            TipRow(icon: "clock", text: "Use auto-timers to keep customers informed")
                            TipRow(icon: "heart", text: "Respond to customer engagement")
                            TipRow(icon: "globe", text: "Add social media links to stay connected")
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
