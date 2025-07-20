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
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced header with modern design
                modernHeaderSection
                
                // Guest mode info banner (when owner is viewing as guest)
                if barViewModel.loggedInBar != nil && !barViewModel.isOwnerMode {
                    modernGuestModeBanner
                }
                
                // Main Content with enhanced styling
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Quick stats card
                        if !barViewModel.getAllBars().isEmpty {
                            quickStatsCard
                        }
                        
                        // Bars grid with improved styling
                        modernBarsGrid
                        
                        // Enhanced bottom statistics
                        if !barViewModel.getAllBars().isEmpty {
                            modernBottomStats
                        }
                    }
                    .padding(.top, 10)
                }
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
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 0) {
            // Main header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // App title with modern typography
                    Text("Bar Status")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Tracker")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .offset(x: 8)
                    
                    // Enhanced subtitle with live data
                    let totalBars = barViewModel.getAllBars().count
                    let openToday = barViewModel.getAllBars().filter { $0.isOpenToday }.count
                    let openNow = barViewModel.getAllBars().filter { $0.status == .open || $0.status == .openingSoon }.count
                    
                    HStack(spacing: 4) {
                        Text("Following")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(totalBars)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text("bars")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if totalBars > 0 {
                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(openNow)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text("open now")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Modern navigation icons
                modernNavigationIcons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Subtle separator
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
    }
    
    // MARK: - Modern Navigation Icons
    var modernNavigationIcons: some View {
        HStack(spacing: 12) {
            // Create Bar - Enhanced
            ModernNavButton(
                icon: "plus",
                gradient: [.purple, .pink],
                action: { showingCreateBar = true }
            )
            
            // Search - Enhanced
            ModernNavButton(
                icon: "magnifyingglass",
                gradient: [.orange, .red],
                action: { showingSearchBars = true }
            )
            
            // Browse - Enhanced
            ModernNavButton(
                icon: "globe",
                gradient: [.green, .teal],
                action: { showingBrowseByLocation = true }
            )
            
            // Biometric - Enhanced
            ModernNavButton(
                icon: "faceid",
                gradient: [.blue, .cyan],
                action: { handleBiometricLogin() }
            )
            
            // Auth - Enhanced
            ModernNavButton(
                icon: barViewModel.isOwnerMode ? "person.fill.badge.minus" : "person.badge.key",
                gradient: barViewModel.isOwnerMode ? [.red, .pink] : [.indigo, .blue],
                action: {
                    if barViewModel.isOwnerMode {
                        showLogoutOptions()
                    } else {
                        showingOwnerLogin = true
                    }
                }
            )
        }
    }
    
    // MARK: - Quick Stats Card
    var quickStatsCard: some View {
        let stats = barViewModel.getBarStatistics()
        
        return VStack(spacing: 16) {
            HStack {
                Text("Quick Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total",
                    value: "\(stats.totalBars)",
                    icon: "building.2.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Open Now",
                    value: "\(stats.openNow)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Open Today",
                    value: "\(stats.openToday)",
                    icon: "calendar.circle.fill",
                    color: .orange
                )
                
                if stats.manualOverrides > 0 {
                    StatCard(
                        title: "Manual",
                        value: "\(stats.manualOverrides)",
                        icon: "hand.raised.fill",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Modern Bars Grid
    var modernBarsGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(barViewModel.getAllBars()) { bar in
                ModernBarCard(
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
    }
    
    // MARK: - Modern Guest Mode Banner
    var modernGuestModeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Guest Mode")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("You're still logged in as owner")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Switch Back") {
                barViewModel.switchToOwnerView()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Modern Bottom Stats
    var modernBottomStats: some View {
        let allBars = barViewModel.getAllBars()
        let barCount = allBars.count
        let openNow = allBars.filter { $0.status == .open || $0.status == .openingSoon }.count
        let manualOverrides = allBars.filter { !$0.isFollowingSchedule }.count
        let autoTransitions = allBars.filter { $0.isAutoTransitionActive }.count
        
        return VStack(spacing: 16) {
            Text("You have \(barCount) favorite \(barCount == 1 ? "bar" : "bars")")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if barCount > 0 {
                HStack(spacing: 16) {
                    ModernStatBadge(
                        icon: "checkmark.circle.fill",
                        text: "\(openNow) open",
                        color: .green
                    )
                    
                    ModernStatBadge(
                        icon: "calendar.circle.fill",
                        text: "Today",
                        color: .blue
                    )
                    
                    if manualOverrides > 0 {
                        ModernStatBadge(
                            icon: "hand.raised.fill",
                            text: "\(manualOverrides) manual",
                            color: .orange
                        )
                    }
                    
                    if autoTransitions > 0 {
                        ModernStatBadge(
                            icon: "timer",
                            text: "\(autoTransitions) auto",
                            color: .purple
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods (unchanged)
    
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

// MARK: - Modern UI Components

struct ModernNavButton: View {
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = false
                }
                action()
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: gradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 4, y: 2)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
    }
}

struct StatCard: View {
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ModernBarCard: View {
    let bar: Bar
    let isOwnerMode: Bool
    @ObservedObject var barViewModel: BarViewModel
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = false
                }
                onTap()
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 0) {
                // Status header
                HStack {
                    Image(systemName: bar.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    if bar.isAutoTransitionActive {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)
                
                Spacer()
                
                // Status icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: bar.status.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Bar info
                VStack(spacing: 6) {
                    Text(bar.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(bar.status.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.medium)
                    
                    if let todaysSchedule = bar.todaysSchedule {
                        Text(todaysSchedule.isOpen ? "Open today" : "Closed today")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            bar.status.color,
                            bar.status.color.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: bar.status.color.opacity(0.3), radius: 8, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernStatBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MainContentView()
}
