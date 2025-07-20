import SwiftUI

struct SearchBarsView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search bars by name", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Results
                if filteredBars.isEmpty && !searchText.isEmpty {
                    // No results for search
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No bars found")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Try searching with a different name")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Clear Search") {
                            searchText = ""
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 50)
                } else if filteredBars.isEmpty && searchText.isEmpty {
                    // No bars available at all
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
                    }
                    .padding(.top, 50)
                } else {
                    // Show search results
                    List(filteredBars) { bar in
                        Button(action: {
                            barViewModel.selectedBar = bar
                            barViewModel.showingDetail = true
                        }) {
                            SearchBarRow(bar: bar)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
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
    
    private var filteredBars: [Bar] {
        let allBars = barViewModel.getAllBars()
        if searchText.isEmpty {
            return allBars
        }
        return allBars.filter { bar in
            bar.name.localizedCaseInsensitiveContains(searchText) ||
            bar.address.localizedCaseInsensitiveContains(searchText) ||
            (bar.location?.city.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (bar.location?.country.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

// MARK: - Search Bar Row (Simplified)
struct SearchBarRow: View {
    let bar: Bar
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            VStack {
                Image(systemName: bar.status.icon)
                    .font(.title2)
                    .foregroundColor(bar.status.color)
                
                Text(bar.status.displayName)
                    .font(.caption2)
                    .foregroundColor(bar.status.color)
            }
            .frame(width: 60)
            
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
                
                // Additional info
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
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "hand.raised.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Manual")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
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
                    }
                }
            }
            
            Spacer()
            
            // Last updated
            VStack(alignment: .trailing) {
                Text("Updated")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(timeAgo(bar.lastUpdated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Makes entire row tappable
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
