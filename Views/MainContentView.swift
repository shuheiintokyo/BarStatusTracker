import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingOwnerLogin = false
    @State private var showingBiometricAlert = false
    @State private var biometricError = ""
    @State private var pendingBiometricNavigation = false // FIXED: Better state management
    @State private var showingCreateBar = false
    @State private var showingSearchBars = false
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                headerSection
                
                // Show message for owners or grid for guests
                if barViewModel.isOwnerMode, let loggedInBar = barViewModel.loggedInBar {
                    // Owner mode - show welcome message and quick access
                    ownerModeSection(loggedInBar: loggedInBar)
                } else {
                    // Guest mode - show favorited bars and action cards
                    guestModeSection
                }
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
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(barViewModel: barViewModel)
        }
        .alert("Authentication Error", isPresented: $showingBiometricAlert) {
            Button("OK") { }
        } message: {
            Text(biometricError)
        }
        // FIXED: Better handling of biometric authentication navigation
        .onChange(of: barViewModel.isOwnerMode) { oldValue, newValue in
            // Only proceed if we're expecting biometric navigation AND login was successful
            if newValue && pendingBiometricNavigation && barViewModel.loggedInBar != nil {
                // Delay slightly to ensure the view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let loggedInBar = barViewModel.loggedInBar {
                        barViewModel.selectedBar = loggedInBar
                        barViewModel.showingDetail = true
                        pendingBiometricNavigation = false
                    }
                }
            } else if !newValue {
                // If logged out, clear pending navigation
                pendingBiometricNavigation = false
            }
        }
        .onAppear {
            // Connect notification manager to view model
            barViewModel.setNotificationManager(notificationManager)
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
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
                    let favoriteCount = barViewModel.userPreferencesManager.getFavoriteBarIds().count
                    if favoriteCount == 0 {
                        Text("Discover and follow bars")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Following \(favoriteCount) \(favoriteCount == 1 ? "bar" : "bars")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Authentication buttons
            authenticationButtons
        }
        .padding()
    }
    
    // MARK: - Authentication Buttons
    var authenticationButtons: some View {
        HStack(spacing: 12) {
            // Notification settings button
            Button(action: {
                showingNotificationSettings = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: notificationManager.isAuthorized ? "bell.fill" : "bell")
                        .font(.title2)
                        .foregroundColor(notificationManager.isAuthorized ? .green : .gray)
                    Text("Alerts")
                        .font(.caption2)
                        .foregroundColor(notificationManager.isAuthorized ? .green : .gray)
                }
            }
            
            // Create bar button (always visible in guest mode)
            if !barViewModel.isOwnerMode {
                Button(action: {
                    showingCreateBar = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        Text("New Bar")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            // Search bars button (always visible in guest mode)
            if !barViewModel.isOwnerMode {
                Button(action: {
                    showingSearchBars = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Search")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // FIXED: Only show biometric button if credentials exist AND biometrics are available
            if barViewModel.canUseBiometricAuth && !barViewModel.isOwnerMode {
                Button(action: {
                    authenticateWithBiometrics()
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
                    
                    if barViewModel.isOwnerMode, let loggedInBar = barViewModel.loggedInBar {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loggedInBar.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Logout")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Owner Mode Section
    func ownerModeSection(loggedInBar: Bar) -> some View {
        VStack(spacing: 20) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You're logged in as the owner of \(loggedInBar.name)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Quick status overview
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: loggedInBar.status.icon)
                        .font(.title)
                        .foregroundColor(loggedInBar.status.color)
                    
                    VStack(alignment: .leading) {
                        Text("Current Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(loggedInBar.status.displayName)
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Favorites")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("\(barViewModel.getFavoriteCount(for: loggedInBar.id))")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Auto-transition info (if active)
                if loggedInBar.isAutoTransitionActive, let pendingStatus = loggedInBar.pendingStatus {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading) {
                            Text("Auto-transition active")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Will change to \(pendingStatus.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        TimeRemainingView(bar: loggedInBar, barViewModel: barViewModel)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            // Main control button
            Button(action: {
                barViewModel.selectedBar = loggedInBar
                barViewModel.showingDetail = true
            }) {
                HStack {
                    Image(systemName: "building.2")
                        .font(.title2)
                    Text("Go to \(loggedInBar.name) Controls")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // View all bars button
            Button(action: {
                // Temporarily switch to guest view while staying logged in
                barViewModel.switchToGuestView()
            }) {
                HStack {
                    Image(systemName: "map")
                        .font(.title2)
                    Text("View All Bars")
                        .font(.headline)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 30)
    }
    
    // MARK: - Guest Mode Section
    var guestModeSection: some View {
        VStack {
            // Show owner info if logged in but in guest view
            if barViewModel.loggedInBar != nil {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Viewing as guest - you're still logged in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Back to Owner View") {
                        barViewModel.switchToOwnerView()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Show bar grid (favorited bars + action cards)
            BarGridView(barViewModel: barViewModel, isOwnerMode: false)
        }
    }
    
    // MARK: - Helper Methods
    
    // FIXED: Better biometric authentication with proper error handling
    private func authenticateWithBiometrics() {
        // First check if we have valid saved credentials
        guard barViewModel.canUseBiometricAuth else {
            biometricError = "Biometric authentication not available"
            showingBiometricAlert = true
            return
        }
        
        // Set pending navigation flag
        pendingBiometricNavigation = true
        
        barViewModel.authenticateWithBiometrics { success, error in
            DispatchQueue.main.async {
                if !success {
                    // Clear pending navigation on failure
                    pendingBiometricNavigation = false
                    biometricError = error ?? "Authentication failed"
                    showingBiometricAlert = true
                }
                // Success case is handled by the onChange modifier
            }
        }
    }
    
    // Show logout options
    private func showLogoutOptions() {
        let alert = UIAlertController(title: "Logout Options", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Logout (Keep \(barViewModel.biometricAuthInfo.displayName))", style: .default) { _ in
            barViewModel.logout()
        })
        
        alert.addAction(UIAlertAction(title: "Full Logout (Clear \(barViewModel.biometricAuthInfo.displayName))", style: .destructive) { _ in
            barViewModel.fullLogout()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Helper View to Fix Dynamic Member Lookup Issue
struct TimeRemainingView: View {
    let bar: Bar
    let barViewModel: BarViewModel
    
    private var timeRemainingText: String? {
        // Calculate time remaining directly from the bar's properties
        guard let timeRemaining = bar.timeUntilAutoTransition,
              timeRemaining > 0 else {
            return nil
        }
        
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        Group {
            if let timeRemaining = timeRemainingText {
                Text(timeRemaining)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
    }
}

#Preview {
    MainContentView()
        .environmentObject(NotificationManager())
}
