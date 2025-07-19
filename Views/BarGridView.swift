import SwiftUI

struct BarGridView: View {
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @State private var showingCreateBar = false
    @State private var showingSearchBars = false
    @State private var showingBrowseByLocation = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    
    // FIXED: Get the appropriate bars to display with better favorites detection
    private var barsToDisplay: [Bar] {
        if isOwnerMode && barViewModel.loggedInBar != nil {
            // Owner mode: show only the logged-in bar
            return barViewModel.getOwnerBars()
        } else {
            // Guest mode: show only favorited bars
            let favoriteBarIds = barViewModel.getFavoriteBarIds()
            let favoriteBars = barViewModel.getAllBars().filter { favoriteBarIds.contains($0.id) }
            
            print("🔍 BarGridView: Displaying \(favoriteBars.count) favorite bars out of \(favoriteBarIds.count) favorites")
            print("🔍 Favorite IDs: \(favoriteBarIds)")
            print("🔍 Available bars: \(barViewModel.getAllBars().map { $0.name })")
            
            return favoriteBars
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                // Guest mode action cards
                if !isOwnerMode {
                    // Create new bar card
                    CreateBarCard {
                        showingCreateBar = true
                    }
                    
                    // Search bars card
                    SearchBarsCard {
                        showingSearchBars = true
                    }
                    
                    // Browse by location card
                    BrowseByLocationCard {
                        showingBrowseByLocation = true
                    }
                }
                
                // Existing bars (favorited bars for guests, owned bar for owners)
                ForEach(barsToDisplay) { bar in
                    BarGridItem(
                        bar: bar,
                        isOwnerMode: isOwnerMode,
                        barViewModel: barViewModel,
                        onTap: {
                            barViewModel.selectedBar = bar
                            barViewModel.showingDetail = true
                        }
                    )
                }
            }
            .padding()
            
            // FIXED: Show appropriate empty state message
            if barsToDisplay.isEmpty && isOwnerMode {
                Text("No bars available")
                    .foregroundColor(.secondary)
                    .padding()
            } else if barsToDisplay.isEmpty && !isOwnerMode {
                // Enhanced empty state for guests
                VStack(spacing: 20) {
                    Image(systemName: "heart")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Favorite Bars Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Use \"Search New Bar\" or \"Browse by Location\" to find and follow bars you like!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Button("Search Bars") {
                                showingSearchBars = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                            
                            Button("Browse by Location") {
                                showingBrowseByLocation = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(25)
                        }
                        
                        Button("Create New Bar") {
                            showingCreateBar = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    // Debug info (only in development)
                    #if DEBUG
                    VStack(spacing: 8) {
                        Text("Debug Info:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        let favoriteIds = barViewModel.getFavoriteBarIds()
                        Text("Favorite IDs: \(favoriteIds.count) - \(favoriteIds.isEmpty ? "None" : Array(favoriteIds).joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Total bars available: \(barViewModel.getAllBars().count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Button("Refresh Favorites") {
                            barViewModel.forceRefreshAllData()
                        }
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    #endif
                }
                .padding(.top, 50)
                .frame(maxWidth: .infinity)
            }
            
            // Show favorites count for debugging
            if !isOwnerMode {
                let favoriteCount = barViewModel.getFavoriteBarIds().count
                Text("You have \(favoriteCount) favorite bars")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            }
        }
        .refreshable {
            // Pull to refresh functionality
            barViewModel.forceRefreshAllData()
        }
        .sheet(isPresented: $showingCreateBar) {
            CreateBarView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingSearchBars) {
            SearchBarsView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingBrowseByLocation) {
            BrowseByLocationView(barViewModel: barViewModel)
        }
        .onAppear {
            // Debug favorites when view appears
            print("🔍 BarGridView appeared - debugging favorites...")
            barViewModel.debugFavorites()
        }
    }
}

// MARK: - Create Bar Card (Same as before)
struct CreateBarCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text("Create New Bar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Set up your bar profile")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Text("🎉 Start managing!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(radius: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Bars Card (Same as before)
struct SearchBarsCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text("Search New Bar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Find bars to follow")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Text("🔍 Discover bars!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(radius: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Browse by Location Card (Same as before)
struct BrowseByLocationCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text("Browse by Location")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Find bars by country & city")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Text("🌍 Explore worldwide!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(radius: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BarGridView(barViewModel: BarViewModel(), isOwnerMode: false)
}
