import SwiftUI

struct BarDetailView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @Environment(\.dismiss) private var dismiss
    
    // Editing states
    @State private var editingDescription = ""
    @State private var showingEditDescription = false
    @State private var showingEditOperatingHours = false
    @State private var showingEditPassword = false
    @State private var editingOperatingHours = OperatingHours()
    @State private var editingPassword = ""
    
    // Analytics and UI state
    @State private var basicAnalytics: [String: Any] = [:]
    @State private var isLoadingAnalytics = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        headerSection
                        
                        Divider()
                        
                        // Quick Stats
                        quickStatsSection
                        
                        Divider()
                        
                        // Operating Hours
                        operatingHoursSection
                        
                        Divider()
                        
                        // Description
                        descriptionSection
                        
                        // Social Links
                        socialLinksSection
                        
                        // Owner Settings
                        if isOwnerMode {
                            Divider()
                            ownerSettingsSection
                        }
                        
                        // Basic Analytics for bar owners
                        if isOwnerMode {
                            Divider()
                            analyticsSection
                        }
                        
                        Spacer(minLength: 100) // Space for floating button
                    }
                    .padding()
                }
                
                // Floating favorite button (for non-owners)
                if !isOwnerMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingFavoriteButton(
                                barId: bar.id,
                                barViewModel: barViewModel
                            )
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if isOwnerMode {
                    loadBasicAnalytics()
                }
            }
        }
        .sheet(isPresented: $showingEditDescription) {
            EditDescriptionView(description: $editingDescription) { newDescription in
                barViewModel.updateBarDescription(bar, newDescription: newDescription)
            }
        }
        .sheet(isPresented: $showingEditOperatingHours) {
            EditOperatingHoursView(
                operatingHours: $editingOperatingHours,
                barName: bar.name
            ) { newHours in
                barViewModel.updateBarOperatingHours(bar, newHours: newHours)
            }
        }
        .sheet(isPresented: $showingEditPassword) {
            EditPasswordView(
                currentPassword: bar.password,
                barName: bar.name
            ) { newPassword in
                barViewModel.updateBarPassword(bar, newPassword: newPassword)
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(bar.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(bar.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: bar.status.icon)
                        .font(.system(size: 40))
                        .foregroundColor(bar.status.color)
                    
                    Text(bar.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // Real-time auto-transition info (if active)
            if bar.isAutoTransitionActive, let pendingStatus = bar.pendingStatus {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("Will automatically change to \(pendingStatus.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let timeRemaining = barViewModel.getTimeRemainingText(for: bar) {
                            Text("Time remaining: \(timeRemaining)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Owner Controls
            if isOwnerMode {
                StatusControlView(bar: bar, barViewModel: barViewModel)
            }
        }
    }
    
    // MARK: - Quick Stats Section
    var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bar Stats")
                    .font(.headline)
                
                Spacer()
                
                // Real-time favorite count for everyone
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("\(barViewModel.getFavoriteCount(for: bar.id))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(barViewModel.getFavoriteCount(for: bar.id) == 1 ? "like" : "likes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !isOwnerMode {
                // Guest view of favorites
                HStack {
                    Image(systemName: barViewModel.isFavorite(barId: bar.id) ? "heart.fill" : "heart")
                        .foregroundColor(barViewModel.isFavorite(barId: bar.id) ? .red : .gray)
                    
                    if barViewModel.isFavorite(barId: bar.id) {
                        Text("You have favorited this bar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Tap the heart to add to favorites and get notifications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Operating Hours Section
    var operatingHoursSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Operating Hours")
                    .font(.headline)
                
                if isOwnerMode {
                    Spacer()
                    Button("Edit") {
                        editingOperatingHours = bar.operatingHours
                        showingEditOperatingHours = true
                    }
                    .font(.caption)
                }
            }
            
            // Today's hours (highlighted)
            if bar.isOpenToday {
                HStack {
                    Text("Today:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(bar.todaysHours.displayText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Text("Today:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Closed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // All week hours
            VStack(spacing: 4) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    let dayHours = bar.operatingHours.getDayHours(for: day)
                    
                    HStack {
                        Text(day.displayName)
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        Spacer()
                        
                        Text(dayHours.displayText)
                            .font(.caption)
                            .foregroundColor(dayHours.isOpen ? .primary : .secondary)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Description Section
    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("About")
                    .font(.headline)
                
                if isOwnerMode {
                    Spacer()
                    Button("Edit") {
                        editingDescription = bar.description
                        showingEditDescription = true
                    }
                    .font(.caption)
                }
            }
            
            Text(bar.description.isEmpty ? "No description available." : bar.description)
                .font(.body)
                .foregroundColor(bar.description.isEmpty ? .secondary : .primary)
        }
    }
    
    // MARK: - Social Links Section
    @ViewBuilder
    var socialLinksSection: some View {
        if !bar.socialLinks.instagram.isEmpty || !bar.socialLinks.twitter.isEmpty || !bar.socialLinks.website.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Follow Us")
                    .font(.headline)
                
                SocialLinksView(socialLinks: bar.socialLinks)
            }
        }
    }
    
    // MARK: - Owner Settings Section
    var ownerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Owner Settings")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Change Password
                HStack {
                    VStack(alignment: .leading) {
                        Text("Login Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Current: ••••")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        editingPassword = bar.password
                        showingEditPassword = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Analytics Section
    var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Customer Analytics")
                    .font(.headline)
                
                Spacer()
                
                if isLoadingAnalytics {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Refresh") {
                        loadBasicAnalytics()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            BasicAnalyticsSection(analyticsData: basicAnalytics)
        }
    }
    
    private func loadBasicAnalytics() {
        isLoadingAnalytics = true
        
        // Get basic analytics through BarViewModel
        barViewModel.getBasicAnalytics(for: bar.id) { data in
            DispatchQueue.main.async {
                self.basicAnalytics = data
                self.isLoadingAnalytics = false
            }
        }
    }
}

// MARK: - Edit Operating Hours View
struct EditOperatingHoursView: View {
    @Binding var operatingHours: OperatingHours
    let barName: String
    let onSave: (OperatingHours) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Set your regular operating hours. These help customers know when you're typically open.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                        
                        ForEach(WeekDay.allCases, id: \.self) { day in
                            DayHoursEditor(
                                day: day,
                                dayHours: Binding(
                                    get: { operatingHours.getDayHours(for: day) },
                                    set: { operatingHours.setDayHours(for: day, hours: $0) }
                                )
                            )
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Operating Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(operatingHours)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Edit Password View
struct EditPasswordView: View {
    let currentPassword: String
    let barName: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var canSave: Bool {
        newPassword.count == 4 && confirmPassword == newPassword && newPassword != currentPassword
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Change Login Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter a new 4-digit password for \(barName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.headline)
                        
                        Text("••••")
                            .font(.title3)
                            .fontFamily(.monospaced)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.headline)
                        
                        SecureField("Enter new 4-digit password", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: newPassword) { _, newValue in
                                if newValue.count > 4 {
                                    newPassword = String(newValue.prefix(4))
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.headline)
                        
                        SecureField("Re-enter new password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: confirmPassword) { _, newValue in
                                if newValue.count > 4 {
                                    confirmPassword = String(newValue.prefix(4))
                                }
                            }
                        
                        if !confirmPassword.isEmpty && confirmPassword != newPassword {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if canSave {
                            onSave(newPassword)
                            dismiss()
                        } else {
                            alertMessage = "Please enter a valid 4-digit password that's different from your current one"
                            showingAlert = true
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .alert("Password Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// Helper extension for monospaced font
extension Text {
    func fontFamily(_ family: Font.Design) -> Text {
        self.font(.system(.caption, design: family))
    }
}
