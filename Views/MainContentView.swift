import SwiftUI

// MARK: - Improved MainContentView (Same class name - no breaking changes)
struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
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
            TabView(selection: $selectedTab) {
                // Home - All bars with smart filtering (renamed from "Bars")
                HomeView(barViewModel: barViewModel)
                    .tabItem {
                        Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                
                // Find Bars - Discovery focused (renamed from "Discover")
                DiscoverView(barViewModel: barViewModel)
                    .tabItem {
                        Label("Find Bars", systemImage: selectedTab == 1 ? "location.fill" : "location")
                    }
                    .tag(1)
                
                // My Account - Owner and profile (renamed from "Profile")
                MyAccountView(
                    barViewModel: barViewModel,
                    showingOwnerLogin: $showingOwnerLogin,
                    showingBiometricAlert: $showingBiometricAlert,
                    showingBiometricNotRegistered: $showingBiometricNotRegistered,
                    biometricError: $biometricError
                )
                .tabItem {
                    Label("My Account", systemImage: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(2)
            }
            .accentColor(.blue)
            
            // Welcome overlay for first-time users
            if showingWelcome {
                WelcomeOverlay(isPresented: $showingWelcome)
            }
        }
        .onAppear {
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

// MARK: - Welcome Flow for First-Time Users
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

// MARK: - Improved Home View (replaces BarsMainView)
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
            .navigationTitle("Bar Status")
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
                
                Button("Discover Bars Near You") {
                    // Switch to discover tab - you can implement this
                }
                .font(.subheadline)
                .foregroundColor(.blue)
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

// MARK: - Quick Actions Sheet
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
                
                Section("Timing") {
                    QuickActionRow(
                        title: "Set Lunch Break (1 hour)",
                        icon: "fork.knife",
                        color: .orange
                    ) {
                        // Implementation for preset timing
                        dismiss()
                    }
                    
                    QuickActionRow(
                        title: "Happy Hour Mode",
                        icon: "party.popper",
                        color: .purple
                    ) {
                        // Implementation for happy hour
                        dismiss()
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

// MARK: - Clean Account View (renamed from ProfileView)
struct MyAccountView: View {
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
                
                // Only essential app info (removed debug sections)
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("My Account")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func ownerSection(for bar: Bar) -> some View {
        Group {
            Section {
                OwnerBarCard(bar: bar, barViewModel: barViewModel)
                
                Button("Manage My Bar") {
                    barViewModel.selectedBar = bar
                    barViewModel.showingDetail = true
                }
                .foregroundColor(.blue)
            } header: {
                Text("Your Bar")
            }
            
            Section("Account") {
                if barViewModel.canUseBiometricAuth {
                    Button("Quick Access Settings") {
                        handleBiometricLogin()
                    }
                    .foregroundColor(.blue)
                }
                
                Button("Switch to Guest View") {
                    barViewModel.switchToGuestView()
                }
                .foregroundColor(.blue)
                
                Button("Sign Out") {
                    showLogoutOptions()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    private var guestSection: some View {
        Section("Bar Owner Access") {
            Button("Sign In as Bar Owner") {
                showingOwnerLogin = true
            }
            .foregroundColor(.blue)
            
            if barViewModel.canUseBiometricAuth {
                Button("Quick Access") {
                    handleBiometricLogin()
                }
                .foregroundColor(.blue)
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
    
    private func showLogoutOptions() {
        let alert = UIAlertController(title: "Sign Out", message: "Choose how you'd like to sign out", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Keep Quick Access", style: .default) { _ in
            barViewModel.logout()
        })
        
        alert.addAction(UIAlertAction(title: "Remove Quick Access", style: .destructive) { _ in
            barViewModel.fullLogout()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
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
