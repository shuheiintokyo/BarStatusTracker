import SwiftUI

struct BarDetailView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var editingDescription = ""
    @State private var showingEditDescription = false
    @State private var basicAnalytics: [String: Any] = [:]
    @State private var isLoadingAnalytics = false
    
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
                        
                        // Basic Analytics for bar owners
                        if isOwnerMode {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("Customer Analytics")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if isLoadingAnalytics {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Button("Refresh") {
                                            loadBasicAnalytics()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                BasicAnalyticsSection(analyticsData: basicAnalytics)
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
            }
            .onAppear {
                if isOwnerMode {
                    loadBasicAnalytics()
                }
            }
        }
        .sheet(isPresented: $showingEditDescription) {
            EditDescriptionView(description: $editingDescription) { newDescription in
                barViewModel.updateBarDescription(bar, newDescription: newDescription)
            }
        }
    }
    
    private func loadBasicAnalytics() {
        isLoadingAnalytics = true
        
        // Get basic analytics through BarViewModel
        barViewModel.getBasicAnalytics(for: bar.id) { data in
            DispatchQueue.main.async {
                self.basicAnalytics = data
                self.isLoadingAnalytics = false
            }
        }
    }
}

// MARK: - Basic Analytics Section
struct BasicAnalyticsSection: View {
    let analyticsData: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            if analyticsData.isEmpty {
                Text("No analytics data yet. Analytics will appear after customers like your bar.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
            } else {
                
                // Total favorites
                if let totalFavorites = analyticsData["totalFavorites"] as? Int {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Total Favorites: \(totalFavorites)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // Device types
                if let deviceTypes = analyticsData["deviceTypes"] as? [String: Int], !deviceTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.blue)
                            Text("Device Types")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        ForEach(deviceTypes.sorted(by: { $0.value > $1.value }), id: \.key) { device, count in
                            HStack {
                                Text("• \(device)")
                                    .font(.body)
                                Spacer()
                                Text("\(count)")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                }
                
                // Countries (if location data available)
                if let countries = analyticsData["countries"] as? [String: Int], !countries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("Countries")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        ForEach(countries.sorted(by: { $0.value > $1.value }), id: \.key) { country, count in
                            HStack {
                                Text("\(countryFlag(for: country)) \(country)")
                                    .font(.body)
                                Spacer()
                                Text("\(count)")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(10)
                }
                
                // Cities (if location data available)
                if let cities = analyticsData["cities"] as? [String: Int], !cities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.orange)
                            Text("Cities")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        ForEach(cities.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { city, count in
                            HStack {
                                Text("• \(city)")
                                    .font(.body)
                                Spacer()
                                Text("\(count)")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(10)
                }
                
                // No location data message
                if let hasLocationData = analyticsData["hasLocationData"] as? Bool, !hasLocationData {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.slash")
                                .foregroundColor(.gray)
                            Text("Location Analytics")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("Some customers haven't shared location data. This is normal and doesn't affect other features.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                }
                
                // Tips section
                TipsSection()
            }
        }
    }
    
    private func countryFlag(for country: String) -> String {
        let flagMap = [
            "Japan": "🇯🇵",
            "United States": "🇺🇸",
            "United Kingdom": "🇬🇧",
            "Australia": "🇦🇺",
            "Canada": "🇨🇦",
            "Germany": "🇩🇪",
            "France": "🇫🇷",
            "Italy": "🇮🇹",
            "Spain": "🇪🇸",
            "South Korea": "🇰🇷"
        ]
        return flagMap[country] ?? "🌍"
    }
}

// MARK: - Tips Section
struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tips to Get More Favorites")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                TipRow(text: "Update your status regularly to keep customers informed")
                TipRow(text: "Add interesting descriptions about your daily specials")
                TipRow(text: "Use auto-timers to let customers know when you're opening/closing")
                TipRow(text: "Respond to customer engagement and build community")
            }
            .padding(.leading)
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .cornerRadius(10)
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.yellow)
                .fontWeight(.bold)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
