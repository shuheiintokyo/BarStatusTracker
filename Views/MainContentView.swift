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
            // STEP 1: SET BACKGROUND AT TOP LEVEL
            Image(backgroundManager.getBackgroundImage(for: "main_app"))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.3)
                .blur(radius: 2.0)
                .ignoresSafeArea(.all) // Cover EVERYTHING
            
            TabView(selection: $selectedTab) {
                // Home - All bars view
                HomeView(barViewModel: barViewModel)
                    .tabItem {
                        Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                
                // Discover - Search and location-based discovery
                DiscoverTabView(barViewModel: barViewModel)
                    .tabItem {
                        Label("Discover", systemImage: selectedTab == 1 ? "location.fill" : "location")
                    }
                    .tag(1)
                
                // My Account - Owner and profile
                MyAccountView(
                    barViewModel: barViewModel,
                    showingOwnerLogin: $showingOwnerLogin,
                    showingBiometricAlert: $showingBiometricAlert,
                    showingBiometricNotRegistered: $showingBiometricNotRegistered,
                    biometricError: $biometricError
                )
                .tabItem {
                    Label("Account", systemImage: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(2)
            }
            .background(Color.clear) // Make TabView transparent
            .accentColor(.blue)
            
            // Welcome overlay for first-time users
            if showingWelcome {
                WelcomeOverlay(isPresented: $showingWelcome)
            }
        }
        .onAppear {
            // STEP 3: Make tab bar background transparent
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.clear
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // DEBUG: You can remove this later
            let imageName = backgroundManager.getBackgroundImage(for: "main_app")
            print("🖼️ Using background: \(imageName)")
            
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
            Text("Quick access is not set up for any bar. Please log in manually first to enable this feature.")
        }
    }
}

// MARK: - STEP 2: Home View (Background Removed, Made Transparent)

struct HomeView: View {
    @ObservedObject var barViewModel: BarViewModel
    @State private var showingCreateBar = false
    @State private var showingQuickActions = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var displayBars: [Bar] {
        let allBars = barViewModel.getAllBars()

        // Smart filtering: show owner's bar first if logged in
        if let loggedInBar = barViewModel.loggedInBar {
            var bars = allBars.filter { $0.id != loggedInBar.id }
            bars.insert(loggedInBar, at: 0)
            return bars
        }

        return allBars
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick stats header (only if bars exist)
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

                // Floating Action Button for quick actions
                if barViewModel.loggedInBar != nil {
                    quickActionsFAB
                }
            }
            .background(Color.clear) // STEP 2: Make transparent
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
                barViewModel.forceRefreshAllData()
            }
        }
        .background(Color.clear) // Make NavigationView transparent too
        .sheet(isPresented: $showingCreateBar) {
            CreateBarView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingQuickActions) {
            if let loggedInBar = barViewModel.loggedInBar {
                QuickActionsSheet(bar: loggedInBar, barViewModel: barViewModel)
            }
        }
    }

    private var quickStatsView: some View {
        HStack(spacing: 16) {
            StatBadge(
                title: "Total",
                value: "\(displayBars.count)",
                color: .blue,
                icon: "building.2"
            )

            StatBadge(
                title: "Open Now",
                value: "\(displayBars.filter { $0.status == .open || $0.status == .openingSoon }.count)",
                color: .green,
                icon: "checkmark.circle"
            )

            StatBadge(
                title: "Open Today",
                value: "\(displayBars.filter { $0.isOpenToday }.count)",
                color: .orange,
                icon: "calendar"
            )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }

    private var emptyHomeState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 80)

            Image(systemName: "building.2")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.6))

            VStack(spacing: 12) {
                Text("Welcome to Bar Status!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create your first bar or discover bars in your area")
                    .font(.body)
                    .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
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

// MARK: - Discover Tab View (Made Transparent)

struct DiscoverTabView: View {
    @ObservedObject var barViewModel: BarViewModel
    @State private var showingSearch = false
    @State private var showingLocationBrowser = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Discover Bars")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Find bars in your area or search by name and location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Discovery options
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
                            // Filter to open bars in search
                            showingSearch = true
                        }
                    }

                    // Quick stats
                    if !barViewModel.getAllBars().isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Stats")
                                .font(.headline)
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
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(Color.clear) // Make transparent
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.clear) // Make NavigationView transparent
        .sheet(isPresented: $showingSearch) {
            SearchBarsView(barViewModel: barViewModel)
        }
        .sheet(isPresented: $showingLocationBrowser) {
            BrowseByLocationView(barViewModel: barViewModel)
        }
    }
}

// MARK: - Account View (Made Transparent)

struct MyAccountView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Binding var showingOwnerLogin: Bool
    @Binding var showingBiometricAlert: Bool
    @Binding var showingBiometricNotRegistered: Bool
    @Binding var biometricError: String

    @State private var showingSignOutOptions = false

    var body: some View {
        NavigationView {
            List {
                if let loggedInBar = barViewModel.loggedInBar {
                    ownerSection(for: loggedInBar)
                } else {
                    guestSection
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
            .background(Color.clear) // Make List transparent
            .scrollContentBackground(.hidden) // Hide List background
            .navigationTitle("My Account")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(Color.clear) // Make NavigationView transparent
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
                    print("🔄 Switching to Guest View...")
                    withAnimation {
                        barViewModel.switchToGuestView()
                    }

                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
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
            if success {
                // Success handled by view model
            } else {
                biometricError = error ?? "Authentication failed"
                showingBiometricAlert = true
            }
        }
    }
}

// MARK: - Supporting Components (No changes needed)

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
