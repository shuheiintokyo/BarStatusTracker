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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation icons
            headerSection
            
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
    
    // MARK: - Header Section (UPDATED with schedule-aware info)
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bar Status Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // UPDATED: Schedule-aware subtitle
                    let totalBars = barViewModel.getAllBars().count
                    let openToday = barViewModel.getAllBars().filter { $0.isOpenToday }.count
                    
                    if totalBars > 0 {
                        Text("Following \(totalBars) \(totalBars == 1 ? "bar" : "bars") • \(openToday) open today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No bars available yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Simple navigation icons (like in screenshot)
                HStack(spacing: 12) {
                    // New Bar icon
                    Button(action: { showingCreateBar = true }) {
                        ZStack {
                            Circle()
                                .fill(.purple)
                                .frame(width: 40, height: 40)
                            Image(systemName: "plus")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Search icon
                    Button(action: { showingSearchBars = true }) {
                        ZStack {
                            Circle()
                                .fill(.orange)
                                .frame(width: 40, height: 40)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Browse by location icon
                    Button(action: { showingBrowseByLocation = true }) {
                        ZStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 40, height: 40)
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Quick biometric access icon
                    Button(action: { handleBiometricLogin() }) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 40, height: 40)
                            Image(systemName: "faceid")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Login/Logout button
                    authenticationButton
                }
            }
        }
        .padding()
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
    
    // MARK: - Bottom Text (UPDATED with schedule awareness)
    var bottomText: some View {
        let allBars = barViewModel.getAllBars()
        let barCount = allBars.count
        let openNow = allBars.filter { $0.status == .open || $0.status == .openingSoon }.count
        let manualOverrides = allBars.filter { !$0.isFollowingSchedule }.count
        
        return VStack(spacing: 8) {
            Text("You have \(barCount) favorite \(barCount == 1 ? "bar" : "bars")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if barCount > 0 {
                HStack(spacing: 16) {
                    Text("\(openNow) open now")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if manualOverrides > 0 {
                        Text("\(manualOverrides) manual override\(manualOverrides == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
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
            ZStack {
                Circle()
                    .fill(barViewModel.isOwnerMode ? .red : .blue)
                    .frame(width: 40, height: 40)
                Image(systemName: barViewModel.isOwnerMode ? "person.fill.badge.minus" : "person.badge.key")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
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

#Preview {
    MainContentView()
}
