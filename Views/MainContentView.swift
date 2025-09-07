import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    @State private var selectedTab = 0
    @State private var showingOwnerLogin = false
    @State private var showingWelcome = false
    
    // Biometric alerts
    @State private var showingBiometricAlert = false
    @State private var biometricError = ""
    @State private var showingBiometricNotRegistered = false
    
    // First launch detection
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    
    var body: some View {
        ZStack {
            // BACKGROUND GRADIENT - Main App Background
            backgroundManager.getBackgroundGradient(for: "main_app").gradient
                .ignoresSafeArea(.all)
            
            // Additional dark overlay for better readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Home - gradient01
                HomeView(barViewModel: barViewModel)
                    .withStylishBackground("home_view")
                    .tabItem {
                        Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                
                // Discover - gradient02
                DiscoverTabView(barViewModel: barViewModel)
                    .withStylishBackground("discover_view")
                    .tabItem {
                        Label("Discover", systemImage: selectedTab == 1 ? "location.fill" : "location")
                    }
                    .tag(1)
                
                // My Account - gradient03
                MyAccountView(
                    barViewModel: barViewModel,
                    showingOwnerLogin: $showingOwnerLogin,
                    showingBiometricAlert: $showingBiometricAlert,
                    showingBiometricNotRegistered: $showingBiometricNotRegistered,
                    biometricError: $biometricError
                )
                .withStylishBackground("account_view")
                .tabItem {
                    Label("Account", systemImage: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(2)
            }
            .background(Color.clear)
            .accentColor(.blue)
            
            // Welcome overlay for first-time users
            if showingWelcome {
                WelcomeOverlay(isPresented: $showingWelcome)
            }
        }
        .onAppear {
            setupTransparentAppearances()
            
            if !hasLaunchedBefore {
                showingWelcome = true
                hasLaunchedBefore = true
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
        .alert("Quick Access Not Set Up", isPresented: $showingBiometricNotRegistered) {
            Button("Login Manually") {
                showingOwnerLogin = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Quick Access is not set up for any bar. Please log in manually first to enable this feature.")
        }
    }
    
    private func setupTransparentAppearances() {
        // Tab Bar Appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation Bar Appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.shadowColor = UIColor.clear
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().backgroundColor = UIColor.clear
    }
}

// MARK: - Updated HomeView with Fixed Schedule Display

struct HomeView: View {
    @ObservedObject var barViewModel: BarViewModel
    @State private var showingCreateBar = false
    @State private var showingQuickActions = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var displayBars: [Bar] {
        let allBars = barViewModel.getAllBars()  // This now returns refreshed schedules

        // FIXED: Check BOTH isOwnerMode AND loggedInBar existence
        if barViewModel.isOwnerMode, let loggedInBar = barViewModel.loggedInBar {
            // Owner mode: prioritize the logged-in bar
            var refreshedLoggedInBar = loggedInBar
            let _ = refreshedLoggedInBar.refreshScheduleIfNeeded()
            
            var bars = allBars.filter { $0.id != refreshedLoggedInBar.id }
            bars.insert(refreshedLoggedInBar, at: 0)
            return bars
        }

        // Guest mode: show all bars in normal order
        return allBars
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick stats header with glass effect - FIXED: Real-time stats
                if !displayBars.isEmpty {
                    quickStatsView
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayBars) { bar in
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

                    if displayBars.isEmpty {
                        emptyHomeState
                    }
                }

                if barViewModel.loggedInBar != nil {
                    quickActionsFAB
                }
            }
            .navigationTitle("Bar Status Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateBar = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                // FIXED: Force refresh both data and schedules
                barViewModel.forceRefreshAllData()
            }
            .onAppear {
                // FIXED: Refresh schedules when view appears
                barViewModel.forceRefreshAllData()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreateBar) {
            CreateBarView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingQuickActions) {
            if let loggedInBar = barViewModel.loggedInBar {
                QuickActionsSheet(bar: loggedInBar, barViewModel: barViewModel)
            }
        }
    }

    // FIXED: Real-time stats calculation
    private var quickStatsView: some View {
        let openNowCount = displayBars.filter {
            let status = $0.status
            return status == .open || status == .openingSoon
        }.count
        
        let openTodayCount = displayBars.filter { bar in
            // Force refresh to get accurate today's schedule
            var refreshedBar = bar
            let _ = refreshedBar.refreshScheduleIfNeeded()
            return refreshedBar.isOpenToday
        }.count
        
        return HStack(spacing: 16) {
            StatBadge(
                title: "Total",
                value: "\(displayBars.count)",
                color: .blue,
                icon: "building.2"
            )

            StatBadge(
                title: "Open Now",
                value: "\(openNowCount)",
                color: .green,
                icon: "checkmark.circle"
            )

            StatBadge(
                title: "Open Today",
                value: "\(openTodayCount)",
                color: .orange,
                icon: "calendar"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    private var emptyHomeState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)

            Image(systemName: "building.2")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.8))

            VStack(spacing: 12) {
                Text("Welcome to Bar Status!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Create your first bar or discover bars in your area")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: { showingCreateBar = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Your Bar")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Text("Or browse the Discover tab to find bars near you")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding()
    }

    private var quickActionsFAB: some View {
        HStack {
            Spacer()
            Button(action: { showingQuickActions = true }) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing)
        }
    }
}

// MARK: - Updated DiscoverTabView with Gradient Background

struct DiscoverTabView: View {
    @ObservedObject var barViewModel: BarViewModel
    @State private var showingSearch = false
    @State private var showingLocationBrowser = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with glass effect
                    VStack(spacing: 16) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.white)

                        Text("Discover Bars")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Find bars in your area or search by name and location")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )

                    // Discovery options with glass effect
                    VStack(spacing: 16) {
                        DiscoveryOptionCard(
                            icon: "magnifyingglass",
                            title: "Search Bars",
                            subtitle: "Search by name, location, or schedule",
                            color: .blue
                        ) {
                            showingSearch = true
                        }

                        DiscoveryOptionCard(
                            icon: "location.fill",
                            title: "Browse by Location",
                            subtitle: "Explore bars by country and city",
                            color: .green
                        ) {
                            showingLocationBrowser = true
                        }

                        DiscoveryOptionCard(
                            icon: "clock.fill",
                            title: "Open Now",
                            subtitle: "Find bars that are currently open",
                            color: .orange
                        ) {
                            showingSearch = true
                        }
                    }

                    // Quick stats with glass effect
                    if !barViewModel.getAllBars().isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Stats")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                QuickStatCard(
                                    title: "Total Bars",
                                    value: "\(barViewModel.getAllBars().count)",
                                    icon: "building.2",
                                    color: .purple
                                )

                                QuickStatCard(
                                    title: "Open Now",
                                    value: "\(barViewModel.getBarsOpenNow().count)",
                                    icon: "checkmark.circle",
                                    color: .green
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                        )
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingSearch) {
            SearchBarsView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingLocationBrowser) {
            BrowseByLocationView(barViewModel: barViewModel)
        }
    }
}

// MARK: - Updated MyAccountView with Gradient Background

struct MyAccountView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Binding var showingOwnerLogin: Bool
    @Binding var showingBiometricAlert: Bool
    @Binding var showingBiometricNotRegistered: Bool
    @Binding var biometricError: String

    @State private var showingSignOutOptions = false

    // FIXED: MyAccountView body in MainContentView.swift
    // Replace the existing body with this:

    var body: some View {
        NavigationView {
            List {
                // FIXED: Check BOTH isOwnerMode AND loggedInBar existence
                if barViewModel.isOwnerMode, let loggedInBar = barViewModel.loggedInBar {
                    ownerSection(for: loggedInBar)
                } else {
                    guestSection
                    
                    // FIXED: Add quick return section if user switched to guest view but has logged in bar
                    if !barViewModel.isOwnerMode && barViewModel.loggedInBar != nil {
                        quickReturnSection
                    }
                }

                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("My Account")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .actionSheet(isPresented: $showingSignOutOptions) {
            ActionSheet(
                title: Text("Sign Out"),
                message: Text("Choose how you'd like to sign out"),
                buttons: [
                    .default(Text("Keep Quick Access")) {
                        barViewModel.logout()
                    },
                    .destructive(Text("Remove Quick Access")) {
                        barViewModel.fullLogout()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var quickReturnSection: some View {
        Section("Quick Return") {
            if let loggedInBar = barViewModel.loggedInBar {
                Button(action: {
                    withAnimation {
                        barViewModel.isOwnerMode = true
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.left")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Return to \(loggedInBar.name)")
                                .foregroundColor(.blue)
                            Text("Switch back to owner mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func ownerSection(for bar: Bar) -> some View {
        Group {
            Section {
                OwnerBarCard(bar: bar, barViewModel: barViewModel)

                Button(action: {
                    barViewModel.selectedBar = bar
                    barViewModel.showingDetail = true
                }) {
                    HStack {
                        Text("Manage My Bar")
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())

            } header: {
                Text("Your Bar")
            }

            Section("Account") {
                if barViewModel.canUseBiometricAuth {
                    Button(action: {
                        handleBiometricLogin()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Quick Access Settings")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button(action: {
                    withAnimation {
                        barViewModel.switchToGuestView()
                    }
                }) {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("Switch to Guest View")
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    showingSignOutOptions = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var guestSection: some View {
        Section("Bar Owner Access") {
            Button(action: {
                showingOwnerLogin = true
            }) {
                HStack {
                    Image(systemName: "person.badge.key")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text("Sign In as Bar Owner")
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if barViewModel.canUseBiometricAuth {
                Button(action: {
                    handleBiometricLogin()
                }) {
                    HStack {
                        Image(systemName: barViewModel.biometricAuthInfo.iconName)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("Quick Access")
                            .foregroundColor(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func handleBiometricLogin() {
        guard barViewModel.isValidBiometricBar() else {
            showingBiometricNotRegistered = true
            return
        }

        barViewModel.authenticateWithBiometrics { success, error in
            if !success {
                biometricError = error ?? "Authentication failed"
                showingBiometricAlert = true
            }
        }
    }
}

// MARK: - Supporting Components

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DiscoveryOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickStatCard: View {
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
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct QuickActionsSheet: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Quick Status Changes") {
                    QuickActionRow(
                        title: bar.status == .open ? "Close Now" : "Open Now",
                        icon: bar.status == .open ? "xmark.circle.fill" : "checkmark.circle.fill",
                        color: bar.status == .open ? .red : .green
                    ) {
                        let newStatus: BarStatus = bar.status == .open ? .closed : .open
                        barViewModel.setManualBarStatus(bar, newStatus: newStatus)
                        dismiss()
                    }

                    QuickActionRow(
                        title: "Follow Schedule",
                        icon: "calendar",
                        color: .blue
                    ) {
                        barViewModel.setBarToFollowSchedule(bar)
                        dismiss()
                    }
                }

                if bar.isAutoTransitionActive {
                    Section("Auto-Transition") {
                        QuickActionRow(
                            title: "Cancel Auto-Change",
                            icon: "timer.square",
                            color: .orange
                        ) {
                            barViewModel.cancelAutoTransition(for: bar)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct QuickActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()
            }
        }
    }
}

struct WelcomeOverlay: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages = [
        WelcomePage(
            icon: "building.2.fill",
            title: "Welcome to Bar Status",
            subtitle: "Keep your customers informed about when you're open",
            color: .blue
        ),
        WelcomePage(
            icon: "calendar.badge.clock",
            title: "Smart Scheduling",
            subtitle: "Set your hours once and let the app handle status updates automatically",
            color: .green
        ),
        WelcomePage(
            icon: "location.fill",
            title: "Get Discovered",
            subtitle: "Help customers find you with location-based discovery",
            color: .purple
        )
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        WelcomePageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 400)

                HStack {
                    Button("Skip") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    } else {
                        Button("Get Started") {
                            isPresented = false
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding()
        }
    }
}

struct WelcomePage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

struct WelcomePageView: View {
    let page: WelcomePage

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.color)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct OwnerBarCard: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bar.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let location = bar.location {
                        Text(location.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: bar.status.icon)
                        .font(.title2)
                        .foregroundColor(bar.status.color)

                    Text(bar.status.displayName)
                        .font(.caption)
                        .foregroundColor(bar.status.color)
                        .fontWeight(.medium)
                }
            }

            if let todaysSchedule = bar.todaysSchedule {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Text("Today: \(todaysSchedule.displayText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    MainContentView()
}
