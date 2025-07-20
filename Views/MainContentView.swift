import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @State private var selectedTab = 0
    @State private var showingOwnerLogin = false
    @State private var showingBiometricAlert = false
    @State private var biometricError = ""
    @State private var showingBiometricNotRegistered = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Bars View
            BarsMainView(barViewModel: barViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "building.2.fill" : "building.2")
                    Text("Bars")
                }
                .tag(0)
            
            // Search & Browse View
            DiscoverView(barViewModel: barViewModel)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    Text("Discover")
                }
                .tag(1)
            
            // Owner/Profile View
            ProfileView(
                barViewModel: barViewModel,
                showingOwnerLogin: $showingOwnerLogin,
                showingBiometricAlert: $showingBiometricAlert,
                showingBiometricNotRegistered: $showingBiometricNotRegistered,
                biometricError: $biometricError
            )
            .tabItem {
                Image(systemName: selectedTab == 2 ? "person.circle.fill" : "person.circle")
                Text("Profile")
            }
            .tag(2)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingOwnerLogin) {
            OwnerLoginView(barViewModel: barViewModel, showingOwnerLogin: $showingOwnerLogin)
        }
        .sheet(isPresented: $barViewModel.showingDetail) {
            if let selectedBar = barViewModel.selectedBar {
                BarDetailView(bar: selectedBar, barViewModel: barViewModel, isOwnerMode: barViewModel.isOwnerMode)
            }
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
}

// MARK: - Main Bars View (Primary Content)
struct BarsMainView: View {
    @ObservedObject var barViewModel: BarViewModel
    @State private var showingCreateBar = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(barViewModel.getAllBars()) { bar in
                        BarGridItem(
                            bar: bar,
                            isOwnerMode: barViewModel.isOwnerMode,
                            barViewModel: barViewModel,
                            onTap: {
                                barViewModel.selectedBar = bar
                                barViewModel.showingDetail = true
                            }
                        )
                    }
                }
                .padding()
                
                // Empty state when no bars
                if barViewModel.getAllBars().isEmpty {
                    emptyBarsState
                }
            }
            .navigationTitle("Bar Status")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateBar = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                barViewModel.forceRefreshAllData()
            }
        }
        .sheet(isPresented: $showingCreateBar) {
            CreateBarView(barViewModel: barViewModel)
        }
    }
    
    private var emptyBarsState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)
            
            Image(systemName: "building.2")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Bars Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create your first bar or discover bars in your area")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button(action: { showingCreateBar = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Bar")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                NavigationLink(destination: DiscoverView(barViewModel: barViewModel)) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Discover Bars")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Discover View (Search & Browse)
struct DiscoverView: View {
    @ObservedObject var barViewModel: BarViewModel
    @State private var showingSearchBars = false
    @State private var showingBrowseByLocation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick stats (if bars exist)
                if !barViewModel.getAllBars().isEmpty {
                    quickStatsHeader
                }
                
                // Discovery options
                ScrollView {
                    VStack(spacing: 20) {
                        discoveryCards
                        
                        if !barViewModel.getAllBars().isEmpty {
                            recentBarsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSearchBars) {
            SearchBarsView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingBrowseByLocation) {
            BrowseByLocationView(barViewModel: barViewModel)
        }
    }
    
    private var quickStatsHeader: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Total",
                value: "\(barViewModel.getAllBars().count)",
                color: .blue
            )
            
            StatCard(
                title: "Open Now",
                value: "\(barViewModel.getAllBars().filter { $0.status == .open || $0.status == .openingSoon }.count)",
                color: .green
            )
            
            StatCard(
                title: "Open Today",
                value: "\(barViewModel.getAllBars().filter { $0.isOpenToday }.count)",
                color: .orange
            )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    private var discoveryCards: some View {
        VStack(spacing: 16) {
            DiscoveryCard(
                title: "Search Bars",
                subtitle: "Find bars by name, location, or schedule",
                icon: "magnifyingglass",
                color: .blue
            ) {
                showingSearchBars = true
            }
            
            DiscoveryCard(
                title: "Browse by Location",
                subtitle: "Explore bars in different cities and countries",
                icon: "globe",
                color: .green
            ) {
                showingBrowseByLocation = true
            }
        }
    }
    
    private var recentBarsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ForEach(Array(barViewModel.getAllBars().sorted { $0.lastUpdated > $1.lastUpdated }.prefix(3))) { bar in
                RecentBarRow(bar: bar, barViewModel: barViewModel)
            }
        }
    }
}

// MARK: - Profile View (Owner Controls)
struct ProfileView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Binding var showingOwnerLogin: Bool
    @Binding var showingBiometricAlert: Bool
    @Binding var showingBiometricNotRegistered: Bool
    @Binding var biometricError: String
    
    var body: some View {
        NavigationView {
            List {
                if let loggedInBar = barViewModel.loggedInBar {
                    ownerSection(for: loggedInBar)
                } else {
                    guestSection
                }
                
                // App info section
                appInfoSection
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func ownerSection(for bar: Bar) -> some View {
        Group {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bar.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Bar Owner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: bar.status.icon)
                            .font(.title2)
                            .foregroundColor(bar.status.color)
                        
                        Text(bar.status.displayName)
                            .font(.caption)
                            .foregroundColor(bar.status.color)
                    }
                }
                .padding(.vertical, 4)
                
                Button("Manage Bar") {
                    barViewModel.selectedBar = bar
                    barViewModel.showingDetail = true
                }
                .foregroundColor(.blue)
            } header: {
                Text("Your Bar")
            }
            
            Section {
                Button("Quick Face ID Access") {
                    handleBiometricLogin()
                }
                .foregroundColor(.blue)
                
                Button("Switch to Guest View") {
                    barViewModel.switchToGuestView()
                }
                .foregroundColor(.blue)
                
                Button("Logout") {
                    showLogoutOptions()
                }
                .foregroundColor(.red)
            } header: {
                Text("Account")
            }
        }
    }
    
    private var guestSection: some View {
        Section {
            Button("Login as Bar Owner") {
                showingOwnerLogin = true
            }
            .foregroundColor(.blue)
            
            if barViewModel.canUseBiometricAuth {
                Button("Quick Access with Face ID") {
                    handleBiometricLogin()
                }
                .foregroundColor(.blue)
            }
        } header: {
            Text("Bar Owner Access")
        }
    }
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.1")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text("9")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("App Information")
        }
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

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DiscoveryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentBarRow: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    var body: some View {
        Button(action: {
            barViewModel.selectedBar = bar
            barViewModel.showingDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bar.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Updated \(timeAgo(bar.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: bar.status.icon)
                        .foregroundColor(bar.status.color)
                    
                    Text(bar.status.displayName)
                        .font(.caption)
                        .foregroundColor(bar.status.color)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    MainContentView()
}
