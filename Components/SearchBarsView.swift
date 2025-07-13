import SwiftUI

struct SearchBarsView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var filteredBars: [Bar] {
        let allBars = barViewModel.getAllBars()
        
        if searchText.isEmpty {
            return allBars
        } else {
            return allBars.filter { bar in
                bar.name.localizedCaseInsensitiveContains(searchText) ||
                bar.address.localizedCaseInsensitiveContains(searchText) ||
                bar.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discover Bars")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Find and follow bars in your area")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search bars by name, location, or description", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Stats
                    HStack {
                        Text("\(filteredBars.count) \(filteredBars.count == 1 ? "bar" : "bars") found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let favoriteCount = barViewModel.userPreferencesManager.getFavoriteBarIds().count
                        Text("\(favoriteCount) in your favorites")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.clear)
                
                Divider()
                
                // Results section
                if filteredBars.isEmpty {
                    emptyStateView
                } else {
                    barsListView
                }
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
        .alert("Bar Added", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Empty State View
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "building.2" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Bars Yet" : "No Results Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(searchText.isEmpty ?
                     "No bars have been registered yet. Be the first to create one!" :
                     "Try searching with different keywords")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button("Create First Bar") {
                    dismiss()
                    // This will trigger the create bar flow in the parent view
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .padding(.top, 50)
    }
    
    // MARK: - Bars List View
    var barsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredBars) { bar in
                    SearchBarCard(
                        bar: bar,
                        barViewModel: barViewModel,
                        onAddToFavorites: { barName in
                            alertMessage = "Added \(barName) to your favorites! You'll now see it on your dashboard and receive notifications."
                            showingAlert = true
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Search Bar Card
struct SearchBarCard: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let onAddToFavorites: (String) -> Void
    @State private var isAnimating = false
    
    private var isFavorited: Bool {
        barViewModel.isFavorite(barId: bar.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bar.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(bar.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: bar.status.icon)
                            .foregroundColor(bar.status.color)
                        Text(bar.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(bar.status.color)
                    }
                    
                    // Favorites count
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption2)
                        Text("\(barViewModel.getFavoriteCount(for: bar.id))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Description (if available)
            if !bar.description.isEmpty {
                Text(bar.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Operating hours for today
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("Today: \(bar.todaysHours.displayText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Auto-transition info
                if bar.isAutoTransitionActive, let pendingStatus = bar.pendingStatus {
                    HStack(spacing: 2) {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("→ \(pendingStatus.displayName)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Add to favorites button
                Button(action: {
                    toggleFavorite()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .foregroundColor(isFavorited ? .red : .gray)
                        Text(isFavorited ? "Favorited" : "Add to Favorites")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isFavorited ? .red : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        isFavorited ?
                        Color.red.opacity(0.1) :
                        Color.gray.opacity(0.1)
                    )
                    .cornerRadius(6)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                .animation(.easeInOut(duration: 0.1), value: isAnimating)
                
                Spacer()
                
                // View details button
                Button(action: {
                    barViewModel.selectedBar = bar
                    barViewModel.showingDetail = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                        Text("View Details")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFavorited ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func toggleFavorite() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isAnimating = true
        }
        
        let wasAlreadyFavorited = isFavorited
        
        barViewModel.toggleFavorite(barId: bar.id) { isNowFavorited in
            DispatchQueue.main.async {
                if !wasAlreadyFavorited && isNowFavorited {
                    onAddToFavorites(bar.name)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isAnimating = false
            }
        }
    }
}

