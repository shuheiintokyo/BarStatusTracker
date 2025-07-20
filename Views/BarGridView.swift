import SwiftUI

struct BarGridView: View {
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @State private var showingCreateBar = false
    @State private var showingSearchBars = false
    @State private var showingBrowseByLocation = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    
    // Simplified: Show appropriate bars based on mode
    private var barsToDisplay: [Bar] {
        if isOwnerMode && barViewModel.loggedInBar != nil {
            // Owner mode: show only the logged-in bar
            return barViewModel.getOwnerBars()
        } else {
            // Guest mode: show all bars
            return barViewModel.getAllBars()
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
                
                // Existing bars (all bars for guests, owned bar for owners)
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
            
            // Show appropriate empty state message
            if barsToDisplay.isEmpty && isOwnerMode {
                Text("No bars available")
                    .foregroundColor(.secondary)
                    .padding()
            } else if barsToDisplay.isEmpty && !isOwnerMode {
                // Empty state for guests when no bars exist
                VStack(spacing: 20) {
                    Image(systemName: "building.2")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Bars Available Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Be the first to create a bar or search for existing ones!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button("Create New Bar") {
                            showingCreateBar = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .cornerRadius(25)
                        
                        Button("Search Bars") {
                            showingSearchBars = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding(.top, 50)
                .frame(maxWidth: .infinity)
            }
            
            // Show total bars count for guests
            if !isOwnerMode && !barsToDisplay.isEmpty {
                Text("Showing \(barsToDisplay.count) bars")
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
    }
}

// MARK: - Create Bar Card
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

// MARK: - Search Bars Card
struct SearchBarsCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text("Search Bars")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Find bars by name")
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

// MARK: - Browse by Location Card
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
