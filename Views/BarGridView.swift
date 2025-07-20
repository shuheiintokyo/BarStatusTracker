import SwiftUI

struct BarGridView: View {
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @State var showingCreateBar = false  // FIXED: Changed from private to internal
    @State var showingSearchBars = false  // FIXED: Changed from private to internal
    @State var showingBrowseByLocation = false  // FIXED: Changed from private to internal
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    
    // FIXED: Changed from private to internal - Simplified: Show appropriate bars based on mode
    var barsToDisplay: [Bar] {
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
                    // Simple create new bar card
                    Button(action: { showingCreateBar = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            Text("Create New Bar")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(15)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Simple search bars card
                    Button(action: { showingSearchBars = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            Text("Search Bars")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(15)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Simple browse by location card
                    Button(action: { showingBrowseByLocation = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "globe.americas.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            Text("Browse by Location")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(15)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                enhancedEmptyStateForGuests
            }
            
            // Show total bars count for guests
            if !barsToDisplay.isEmpty {
                enhancedBottomText
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
    
    // MARK: - Simple implementations for UI
    var openBarsCount: Int {
        barsToDisplay.filter { $0.status == .open || $0.status == .openingSoon }.count
    }
    
    var barsOpenTodayCount: Int {
        barsToDisplay.filter { $0.isOpenToday }.count
    }
    
    var manualOverrideCount: Int {
        barsToDisplay.filter { !$0.isFollowingSchedule }.count
    }
    
    var enhancedEmptyStateForGuests: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Bars Available Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Be the first to create a bar!")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Create New Bar") {
                showingCreateBar = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.purple)
            .cornerRadius(10)
        }
        .padding(.top, 50)
    }
    
    var enhancedBottomText: some View {
        VStack(spacing: 8) {
            let barCount = barsToDisplay.count
            Text("You have \(barCount) favorite \(barCount == 1 ? "bar" : "bars")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if barCount > 0 {
                HStack(spacing: 16) {
                    Text("\(openBarsCount) open now")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("\(barsOpenTodayCount) open today")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if manualOverrideCount > 0 {
                        Text("\(manualOverrideCount) manual")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    BarGridView(barViewModel: BarViewModel(), isOwnerMode: false)
}
