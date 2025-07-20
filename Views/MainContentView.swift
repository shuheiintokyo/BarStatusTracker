import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @State private var showingOwnerLogin = false
    @State private var showingBiometricAlert = false
    @State private var biometricError = ""
    @State private var showingCreateBar = false
    @State private var showingSearchBars = false
    @State private var showingBrowseByLocation = false
    @State private var showingBiometricNotRegistered = false
    @State private var selectedTab = 0 // 0=New Bar, 1=Search, 2=Quick
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and login
            headerSection
            
            // Top Navigation Tabs (KEEP THIS - exactly like screenshot)
            topNavigationTabs
            
            // Guest mode info banner (when owner is viewing as guest)
            if barViewModel.loggedInBar != nil && !barViewModel.isOwnerMode {
                guestModeBanner
            }
            
            // Main Content - Just the bars list (NO ACTION CARDS)
            ScrollView {
                barsOnlyGrid
            }
            
            // Bottom text
            if !barViewModel.getAllBars().isEmpty {
                bottomText
            }
        }
        .sheet(isPresented: $showingOwnerLogin) {
            OwnerLoginView(barViewModel: barViewModel, showingOwnerLogin: $showingOwnerLogin)
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
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bar Status Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    let totalBars = barViewModel.getAllBars().count
                    Text("Following \(totalBars) \(totalBars == 1 ? "bar" : "bars")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Login/Logout button
                authenticationButton
            }
        }
        .padding()
    }
    
    // MARK: - Top Navigation Tabs (No Alerts - just the 3 main tabs)
    var topNavigationTabs: some View {
        HStack(spacing: 20) {
            // New Bar tab
            TabButton(
                icon: "plus",
                title: "New Bar",
                color: .purple,
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
                showingCreateBar = true
            }
            
            // Search tab
            TabButton(
                icon: "magnifyingglass",
                title: "Search",
                color: .orange,
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
                showingSearchBars = true
            }
            
            // Quick tab
            TabButton(
                icon: "faceid",
                title: "Quick",
                color: .blue,
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
                handleBiometricLogin()
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Guest Mode Banner
    var guestModeBanner: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            
            Text("Viewing as guest - you're still logged in")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Back to Owner View") {
                barViewModel.switchToOwnerView()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
    
    // MARK: - Bars Only Grid (NO ACTION CARDS)
    var barsOnlyGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
        
        return LazyVGrid(columns: columns, spacing: 15) {
            // ONLY show actual bars - NO action cards
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
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    // MARK: - Bottom Text
    var bottomText: some View {
        let barCount = barViewModel.getAllBars().count
        return Text("You have \(barCount) favorite \(barCount == 1 ? "bar" : "bars")")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.vertical, 20)
    }
    
    // MARK: - Authentication Button
    var authenticationButton: some View {
        Button(action: {
            if barViewModel.isOwnerMode {
                showLogoutOptions()
            } else {
                showingOwnerLogin = true
            }
        }) {
            Image(systemName: barViewModel.isOwnerMode ? "person.fill.badge.minus" : "person.badge.key")
                .font(.title2)
                .foregroundColor(barViewModel.isOwnerMode ? .red : .blue)
        }
    }
    
    // MARK: - Helper Methods
    
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

// MARK: - Tab Button Component
struct TabButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(color)
                    .fontWeight(.medium)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainContentView()
}
