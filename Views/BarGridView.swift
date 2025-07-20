import SwiftUI

struct BarGridView: View {
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    
    // Simplified: Show appropriate bars based on mode
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
                // Only show bar cards - no action cards since those are in tabs now
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
            if barsToDisplay.isEmpty {
                emptyStateView
            }
        }
        .refreshable {
            // Pull to refresh functionality
            barViewModel.forceRefreshAllData()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            if isOwnerMode {
                Text("No owned bars")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create a bar to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text("No bars found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Check the Discover tab to find bars")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 50)
    }
}

#Preview {
    BarGridView(barViewModel: BarViewModel(), isOwnerMode: false)
}
