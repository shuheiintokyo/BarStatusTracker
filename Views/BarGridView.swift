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
            VStack(spacing: 20) {
                if !barsToDisplay.isEmpty {
                    // Quick stats section with liquid glass
                    quickStatsSection
                }
                
                LazyVGrid(columns: columns, spacing: 15) {
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
                .padding(.horizontal)
                
                // Show appropriate empty state message
                if barsToDisplay.isEmpty {
                    emptyStateView
                }
            }
        }
        .background(.regularMaterial)
        .refreshable {
            // Pull to refresh functionality
            barViewModel.forceRefreshAllData()
        }
    }
    
    // MARK: - Quick Stats Section with Liquid Glass
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            LiquidGlassSectionHeader("Quick Overview")
            
            HStack(spacing: 12) {
                GridQuickStatCard(
                    title: "Total",
                    value: "\(barsToDisplay.count)",
                    icon: "building.2",
                    color: .blue
                )
                
                GridQuickStatCard(
                    title: "Open Now",
                    value: "\(barsToDisplay.filter { $0.status == .open || $0.status == .openingSoon }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                GridQuickStatCard(
                    title: "Open Today",
                    value: "\(barsToDisplay.filter { $0.isOpenToday }.count)",
                    icon: "calendar",
                    color: .orange
                )
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
        .padding(.horizontal)
    }
    
    // MARK: - Empty State with Liquid Glass
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 12) {
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
            
            if isOwnerMode {
                Button("Create Your First Bar") {
                    // Action to create bar would be handled by parent
                }
                .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
                .foregroundColor(.blue)
            }
        }
        .padding(.top, 50)
        .liquidGlass(level: .regular, cornerRadius: .extraLarge, shadow: .prominent)
        .padding()
    }
}

// MARK: - Grid Quick Stat Card Component with Liquid Glass (Renamed to avoid conflicts)
struct GridQuickStatCard: View {
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
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    BarGridView(barViewModel: BarViewModel(), isOwnerMode: false)
}
