import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @State private var showingOwnerLogin = false
    @State private var showingBiometricAlert = false
    @State private var biometricError = ""
    @State private var autoShowingDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Bar Status Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Authentication buttons
                    HStack(spacing: 12) {
                        // Biometric authentication button (if available)
                        if barViewModel.canUseBiometricAuth {
                            Button(action: {
                                authenticateWithBiometrics()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: barViewModel.biometricAuthInfo.iconName)
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Quick Access")
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
                                        Text("Tap to logout")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                
                // Show message for owners or grid for guests
                if barViewModel.isOwnerMode, let loggedInBar = barViewModel.loggedInBar {
                    // Owner mode - show welcome message and quick access
                    VStack(spacing: 20) {
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("You're logged in as the owner of \(loggedInBar.name)")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
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
                                Text("View All Bars in Town")
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
                    .padding(.top, 50)
                } else {
                    // Guest mode - show all bars
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
                        
                        BarGridView(barViewModel: barViewModel, isOwnerMode: false)
                    }
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
        .alert("Authentication Error", isPresented: $showingBiometricAlert) {
            Button("OK") { }
        } message: {
            Text(biometricError)
        }
        // Auto-show detail page after Face ID login
        .onChange(of: barViewModel.isOwnerMode) { isOwnerMode in
            if isOwnerMode && autoShowingDetail, let loggedInBar = barViewModel.loggedInBar {
                // Delay slightly to ensure the view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    barViewModel.selectedBar = loggedInBar
                    barViewModel.showingDetail = true
                    autoShowingDetail = false
                }
            }
        }
    }
    
    // Biometric authentication with auto-navigation
    private func authenticateWithBiometrics() {
        autoShowingDetail = true
        barViewModel.authenticateWithBiometrics { success, error in
            if !success {
                autoShowingDetail = false
                biometricError = error ?? "Authentication failed"
                showingBiometricAlert = true
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
