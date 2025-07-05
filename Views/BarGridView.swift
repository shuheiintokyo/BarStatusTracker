import SwiftUI

struct BarGridView: View {
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    
    // Get the appropriate bars to display
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
            if barsToDisplay.isEmpty {
                Text("No bars available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(barsToDisplay) { bar in
                        BarGridItem(
                            bar: bar,
                            isOwnerMode: isOwnerMode,
                            barViewModel: barViewModel,  // Changed from userPreferencesManager: barViewModel.userPreferencesManager
                            onTap: {
                                barViewModel.selectedBar = bar
                                barViewModel.showingDetail = true
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}
