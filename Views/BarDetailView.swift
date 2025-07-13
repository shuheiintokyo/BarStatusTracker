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
    
    // Social Links editing states
    @State private var editingSocialLinks = SocialLinks()
    @State private var showingEditSocialLinks = false
    
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
                        
                        Divider()
                        
                        // Social Links with editing capability
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
        .sheet(isPresented: $showingEditSocialLinks) {
            EditSocialLinksView(
                socialLinks: $editingSocialLinks,
                barName: bar.name
            ) { newSocialLinks in
                barViewModel.updateBarSocialLinks(bar, newSocialLinks: newSocialLinks)
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
    
    // MARK: - Social Links Section with Full Editing Support
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Social Links")
                    .font(.headline)
                
                if isOwnerMode {
                    Spacer()
                    Button("Edit") {
                        editingSocialLinks = bar.socialLinks
                        showingEditSocialLinks = true
                    }
                    .font(.caption)
                }
            }
            
            if !bar.socialLinks.instagram.isEmpty ||
               !bar.socialLinks.twitter.isEmpty ||
               !bar.socialLinks.website.isEmpty ||
               !bar.socialLinks.facebook.isEmpty {
                
                SocialLinksView(socialLinks: bar.socialLinks)
            } else if isOwnerMode {
                // Show placeholder for owners when no links are set
                VStack(spacing: 8) {
                    Text("No social links set up yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your social media profiles to help customers find you online")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
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

// MARK: - Edit Operating Hours View (Updated with Dual Slider)
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
                        Text("Set your regular operating hours using the dual-handle sliders. Drag the green circles to set opening and closing times (6 PM - 6 AM, 30-minute increments).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                        
                        ForEach(WeekDay.allCases, id: \.self) { day in
                            ImprovedDayHoursEditor(
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

// MARK: - Edit Social Links View
struct EditSocialLinksView: View {
    @Binding var socialLinks: SocialLinks
    let barName: String
    let onSave: (SocialLinks) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempInstagram = ""
    @State private var tempTwitter = ""
    @State private var tempFacebook = ""
    @State private var tempWebsite = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Social Links")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help customers find \(barName) online")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 20) {
                        // Instagram
                        SocialLinkEditor(
                            icon: "instagram-icon",
                            title: "Instagram",
                            placeholder: "https://instagram.com/yourbar",
                            text: $tempInstagram,
                            description: "Your Instagram profile or page",
                            isAssetImage: true
                        )
                        
                        // Twitter/X
                        SocialLinkEditor(
                            icon: "x-icon",
                            title: "X (Twitter)",
                            placeholder: "https://x.com/yourbar",
                            text: $tempTwitter,
                            description: "Your X (Twitter) profile or page",
                            isAssetImage: true
                        )
                        
                        // Facebook
                        SocialLinkEditor(
                            icon: "facebook-icon",
                            title: "Facebook",
                            placeholder: "https://facebook.com/yourbar",
                            text: $tempFacebook,
                            description: "Your Facebook page",
                            isAssetImage: true
                        )
                        
                        // Website
                        SocialLinkEditor(
                            icon: "globe",
                            title: "Website",
                            placeholder: "https://yourbar.com",
                            text: $tempWebsite,
                            description: "Your official website",
                            isAssetImage: false
                        )
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Tips")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Make sure URLs start with 'https://' or 'http://'")
                            Text("• Leave fields empty if you don't have that social media")
                            Text("• Test your links after saving to make sure they work")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Edit Social Links")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSocialLinks()
                    }
                }
            }
        }
        .onAppear {
            // Load current values
            tempInstagram = socialLinks.instagram
            tempTwitter = socialLinks.twitter
            tempFacebook = socialLinks.facebook
            tempWebsite = socialLinks.website
        }
    }
    
    private func saveSocialLinks() {
        // Validate URLs (basic check)
        let validatedSocialLinks = SocialLinks(
            instagram: validateURL(tempInstagram),
            twitter: validateURL(tempTwitter),
            facebook: validateURL(tempFacebook),
            website: validateURL(tempWebsite)
        )
        
        onSave(validatedSocialLinks)
        dismiss()
    }
    
    private func validateURL(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If empty, return empty
        if trimmed.isEmpty {
            return ""
        }
        
        // If it doesn't start with http:// or https://, add https://
        if !trimmed.lowercased().hasPrefix("http://") && !trimmed.lowercased().hasPrefix("https://") {
            return "https://" + trimmed
        }
        
        return trimmed
    }
}

// MARK: - Social Link Editor Component
struct SocialLinkEditor: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let description: String
    let isAssetImage: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Use either asset image or system image based on isAssetImage flag
                if isAssetImage {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text(title)
                    .font(.headline)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// Helper extension for monospaced font
extension Text {
    func fontFamily(_ family: Font.Design) -> Text {
        self.font(.system(.caption, design: family))
    }
}

// MARK: - Basic Analytics Section
struct BasicAnalyticsSection: View {
    let analyticsData: [String: Any]
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(analyticsData.keys.sorted(), id: \.self) { key in
                Text("\(key): \(String(describing: analyticsData[key]!))")
                    .font(.caption)
            }
        }
    }
}

#Preview {
    let sampleBar = Bar(name: "Sample Bar", address: "123 Main St", username: "Sample Bar", password: "1234")
    BarDetailView(bar: sampleBar, barViewModel: BarViewModel(), isOwnerMode: false)
}
