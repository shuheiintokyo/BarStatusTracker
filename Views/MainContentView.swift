import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @State private var showingOwnerLogin = false
    @State private var showingBiometricAlert = false
    @State private var biometricError = ""
    @State private var showingCreateBar = false
    @State private var showingSearchBars = false
    @State private var showingBiometricNotRegistered = false
    
    // Filter states
    @State private var searchText = ""
    @State private var selectedStatusFilter: BarStatus? = nil
    @State private var selectedLocationFilter: String? = nil
    
    // Filtered bars based on search and filters
    private var filteredBars: [Bar] {
        var bars = barViewModel.getAllBars()
        
        // Apply search filter
        if !searchText.isEmpty {
            bars = bars.filter { bar in
                bar.name.localizedCaseInsensitiveContains(searchText) ||
                bar.address.localizedCaseInsensitiveContains(searchText) ||
                (bar.location?.city.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (bar.location?.country.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply status filter
        if let statusFilter = selectedStatusFilter {
            bars = bars.filter { $0.status == statusFilter }
        }
        
        // Apply location filter
        if let locationFilter = selectedLocationFilter {
            bars = bars.filter { bar in
                bar.location?.city == locationFilter || bar.location?.country == locationFilter
            }
        }
        
        return bars
    }
    
    // Get unique locations for filter
    private var availableLocations: [String] {
        let allBars = barViewModel.getAllBars()
        var locations = Set<String>()
        
        for bar in allBars {
            if let location = bar.location {
                locations.insert(location.city)
                locations.insert(location.country)
            }
        }
        
        return Array(locations).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with actions
                headerSection
                
                // Search and filters
                filterSection
                
                // Bar list
                barListSection
            }
        }
        .sheet(isPresented: $showingOwnerLogin) {
            OwnerLoginView(barViewModel: barViewModel, showingOwnerLogin: $showingOwnerLogin)
        }
        .sheet(isPresented: $barViewModel.showingDetail) {
            if let selectedBar = barViewModel.selectedBar {
                BarDetailView(bar: selectedBar, barViewModel: barViewModel, isOwnerMode: barViewModel.isOwnerMode)
            }
        }
        .sheet(isPresented: $showingCreateBar) {
            CreateBarView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingSearchBars) {
            SearchBarsView(barViewModel: barViewModel)
        }
        .alert("Authentication Error", isPresented: $showingBiometricAlert) {
            Button("OK") { }
        } message: {
            Text(biometricError)
        }
        .alert("Face ID Not Set Up", isPresented: $showingBiometricNotRegistered) {
            Button("Use Manual Login") {
                showingOwnerLogin = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Face ID login is not set up for any bar account. Please log in manually first, then enable Face ID in the settings.")
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bar Status Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if barViewModel.isOwnerMode {
                        Text("Owner Dashboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        let totalBars = barViewModel.getAllBars().count
                        let filteredCount = filteredBars.count
                        if totalBars == 0 {
                            Text("No bars available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if filteredCount != totalBars {
                            Text("Showing \(filteredCount) of \(totalBars) bars")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(totalBars) \(totalBars == 1 ? "bar" : "bars") available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Authentication buttons
                authenticationButtons
            }
            
            // Action buttons (Create New Bar and Search)
            if !barViewModel.isOwnerMode {
                actionButtonsSection
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Authentication Buttons
    var authenticationButtons: some View {
        HStack(spacing: 12) {
            // Biometric authentication button
            if !barViewModel.isOwnerMode && shouldShowBiometricButton {
                Button(action: {
                    handleBiometricLogin()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: barViewModel.biometricAuthInfo.iconName)
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Quick")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Main login/logout button
            Button(action: {
                if barViewModel.isOwnerMode {
                    showLogoutOptions()
                } else {
                    showingOwnerLogin = true
                }
            }) {
                HStack {
                    Image(systemName: barViewModel.isOwnerMode ? "person.fill.badge.minus" : "person.badge.key")
                        .font(.title2)
                        .foregroundColor(barViewModel.isOwnerMode ? .red : .blue)
                    
                    if barViewModel.isOwnerMode, let loggedInBar = barViewModel.loggedInBar {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loggedInBar.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Logout")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Login")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Create New Bar
            Button(action: {
                showingCreateBar = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Create New Bar")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Search Bars
            Button(action: {
                showingSearchBars = true
            }) {
                HStack {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title3)
                    Text("Search Bars")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .pink]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Filter Section
    var filterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search bars by name, location...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Status filters
                    ForEach(BarStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.displayName,
                            isSelected: selectedStatusFilter == status,
                            color: status.color
                        ) {
                            selectedStatusFilter = selectedStatusFilter == status ? nil : status
                        }
                    }
                    
                    // Location filters
                    if !availableLocations.isEmpty {
                        ForEach(availableLocations.prefix(5), id: \.self) { location in
                            FilterChip(
                                title: location,
                                isSelected: selectedLocationFilter == location,
                                color: .green
                            ) {
                                selectedLocationFilter = selectedLocationFilter == location ? nil : location
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Bar List Section
    var barListSection: some View {
        Group {
            if filteredBars.isEmpty {
                emptyStateView
            } else {
                List(filteredBars) { bar in
                    BarListRow(bar: bar, barViewModel: barViewModel, isOwnerMode: barViewModel.isOwnerMode)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    barViewModel.forceRefreshAllData()
                }
            }
        }
    }
    
    // MARK: - Empty State View
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Bars Available" : "No Bars Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if searchText.isEmpty {
                    Text("Be the first to create a bar!")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Text("Try adjusting your search or filters")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if searchText.isEmpty {
                Button("Create New Bar") {
                    showingCreateBar = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.purple)
                .cornerRadius(25)
            } else {
                Button("Clear Search") {
                    searchText = ""
                    selectedStatusFilter = nil
                    selectedLocationFilter = nil
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding(.top, 50)
    }
    
    // MARK: - Helper Methods
    
    private var shouldShowBiometricButton: Bool {
        guard barViewModel.biometricAuthInfo.displayName != "Biometric" else {
            return false
        }
        
        return barViewModel.canUseBiometricAuth && barViewModel.isValidBiometricBar()
    }
    
    private func handleBiometricLogin() {
        guard barViewModel.isValidBiometricBar() else {
            showingBiometricNotRegistered = true
            return
        }
        
        barViewModel.authenticateWithBiometrics { success, error in
            if success {
                if let loggedInBar = barViewModel.loggedInBar {
                    barViewModel.selectedBar = loggedInBar
                    barViewModel.showingDetail = true
                }
            } else {
                biometricError = error ?? "Authentication failed"
                showingBiometricAlert = true
            }
        }
    }
    
    private func showLogoutOptions() {
        let alert = UIAlertController(title: "Logout Options", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Logout (Keep \(barViewModel.biometricAuthInfo.displayName))", style: .default) { _ in
            barViewModel.logout()
        })
        
        alert.addAction(UIAlertAction(title: "Full Logout (Clear \(barViewModel.biometricAuthInfo.displayName))", style: .destructive) { _ in
            barViewModel.fullLogout()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? color : Color.gray.opacity(0.2)
                )
                .foregroundColor(
                    isSelected ? .white : .primary
                )
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Bar List Row Component
struct BarListRow: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    
    var body: some View {
        Button(action: {
            barViewModel.selectedBar = bar
            barViewModel.showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Status indicator
                VStack {
                    Image(systemName: bar.status.icon)
                        .font(.title2)
                        .foregroundColor(bar.status.color)
                    
                    Text(bar.status.displayName)
                        .font(.caption2)
                        .foregroundColor(bar.status.color)
                        .fontWeight(.medium)
                }
                .frame(width: 70)
                
                // Bar details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(bar.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isOwnerMode && barViewModel.loggedInBar?.id == bar.id {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        
                        Spacer()
                    }
                    
                    if let location = bar.location {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(location.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if !bar.address.isEmpty {
                        HStack {
                            Image(systemName: "mappin")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(bar.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Status source info
                    HStack(spacing: 8) {
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
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(timeAgo(bar.lastUpdated))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
    MainContentView()
}
