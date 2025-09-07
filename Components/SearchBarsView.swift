import SwiftUI

struct SearchBarsView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    
    enum SearchFilter: String, CaseIterable {
        case all = "All Bars"
        case open = "Open Now"
        case openToday = "Open Today"
        case manual = "Manual Override"
        case following = "Following Schedule"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar with liquid glass
                searchBarSection
                
                // Filter options with liquid glass
                filterSection
                
                // Results
                if filteredBars.isEmpty && !searchText.isEmpty {
                    noResultsView
                } else if filteredBars.isEmpty && searchText.isEmpty {
                    noBarsView
                } else {
                    resultsSection
                }
                
                Spacer()
            }
            .background(.regularMaterial)
            .navigationTitle("Search Bars")
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
    
    // MARK: - Search Bar Section with Liquid Glass
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search bars by name, location, or schedule", text: $searchText)
                .textFieldStyle(LiquidGlassTextFieldStyle())
        }
        .liquidGlass(level: .regular, cornerRadius: .medium, shadow: .subtle)
        .padding()
    }
    
    // MARK: - Filter Section with Liquid Glass
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        List(filteredBars) { bar in
            Button(action: {
                barViewModel.selectedBar = bar
                barViewModel.showingDetail = true
            }) {
                SearchBarRow(bar: bar)
            }
            .buttonStyle(PlainButtonStyle())
            .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Empty States with Liquid Glass
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No bars found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try searching with a different name or adjust your filters")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Search") {
                searchText = ""
                selectedFilter = .all
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.top, 50)
        .liquidGlass(level: .regular, cornerRadius: .extraLarge, shadow: .medium)
        .padding()
    }
    
    private var noBarsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No bars available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Be the first to create a bar!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create New Bar") {
                dismiss()
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.top, 50)
        .liquidGlass(level: .regular, cornerRadius: .extraLarge, shadow: .medium)
        .padding()
    }
    
    // MARK: - Enhanced filtering with schedule-based search
    private var filteredBars: [Bar] {
        let allBars = barViewModel.getAllBars()
        
        let filteredByType: [Bar]
        switch selectedFilter {
        case .all:
            filteredByType = allBars
        case .open:
            filteredByType = allBars.filter { $0.status == .open || $0.status == .openingSoon }
        case .openToday:
            filteredByType = allBars.filter { $0.isOpenToday }
        case .manual:
            filteredByType = allBars.filter { !$0.isFollowingSchedule }
        case .following:
            filteredByType = allBars.filter { $0.isFollowingSchedule }
        }
        
        if searchText.isEmpty {
            return filteredByType
        }
        
        return filteredByType.filter { bar in
            bar.name.localizedCaseInsensitiveContains(searchText) ||
            bar.address.localizedCaseInsensitiveContains(searchText) ||
            bar.description.localizedCaseInsensitiveContains(searchText) ||
            (bar.location?.city.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (bar.location?.country.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (bar.todaysSchedule?.displayText.localizedCaseInsensitiveContains(searchText) ?? false) ||
            bar.status.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func getFilterCount(_ filter: SearchFilter) -> Int {
        let allBars = barViewModel.getAllBars()
        switch filter {
        case .all:
            return allBars.count
        case .open:
            return allBars.filter { $0.status == .open || $0.status == .openingSoon }.count
        case .openToday:
            return allBars.filter { $0.isOpenToday }.count
        case .manual:
            return allBars.filter { !$0.isFollowingSchedule }.count
        case .following:
            return allBars.filter { $0.isFollowingSchedule }.count
        }
    }
}

// MARK: - Filter Chip Component with Liquid Glass
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? Color.white.opacity(0.3) : .thinMaterial,
                            in: Capsule()
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                .thinMaterial,
                in: Capsule()
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                Capsule()
                    .stroke(.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Enhanced Search Bar Row with Liquid Glass
struct SearchBarRow: View {
    let bar: Bar
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator with liquid glass
            LiquidGlassStatusIndicator(status: bar.status, size: 50)
            
            // Bar info
            VStack(alignment: .leading, spacing: 4) {
                Text(bar.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Location info
                if let location = bar.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(location.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !bar.address.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(bar.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Enhanced status and schedule info
                HStack(spacing: 8) {
                    // Status source indicator
                    if bar.isFollowingSchedule {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("Schedule")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "hand.raised.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Manual")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    }
                    
                    // Today's schedule info
                    if let todaysSchedule = bar.todaysSchedule {
                        HStack(spacing: 2) {
                            Image(systemName: todaysSchedule.isOpen ? "clock" : "moon")
                                .font(.caption2)
                                .foregroundColor(todaysSchedule.isOpen ? .blue : .gray)
                            Text(todaysSchedule.isOpen ? "Open today" : "Closed today")
                                .font(.caption2)
                                .foregroundColor(todaysSchedule.isOpen ? .blue : .gray)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            todaysSchedule.isOpen ? .blue.opacity(0.1) : .gray.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 4)
                        )
                    }
                    
                    // Auto-transition indicator
                    if bar.isAutoTransitionActive {
                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Auto")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            
            Spacer()
            
            // Last updated and schedule preview
            VStack(alignment: .trailing, spacing: 4) {
                Text("Updated")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(timeAgo(bar.lastUpdated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                // Today's hours preview
                if let todaysSchedule = bar.todaysSchedule, todaysSchedule.isOpen {
                    Text(todaysSchedule.displayText)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

#Preview {
    SearchBarsView(barViewModel: BarViewModel())
}
