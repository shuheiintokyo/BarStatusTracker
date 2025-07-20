import SwiftUI

struct BarDetailView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @Environment(\.dismiss) private var dismiss
    
    // Get the current bar state from the view model to ensure real-time updates
    private var currentBar: Bar {
        return barViewModel.bars.first { $0.id == bar.id } ?? bar
    }
    
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
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
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditDescription) {
            EditDescriptionView(description: $editingDescription) { newDescription in
                barViewModel.updateBarDescription(currentBar, newDescription: newDescription)
            }
        }
        .sheet(isPresented: $showingEditOperatingHours) {
            EditOperatingHoursView(
                operatingHours: $editingOperatingHours,
                barName: currentBar.name
            ) { newHours in
                barViewModel.updateBarOperatingHours(currentBar, newHours: newHours)
            }
        }
        .sheet(isPresented: $showingEditPassword) {
            EditPasswordView(
                currentPassword: currentBar.password,
                barName: currentBar.name
            ) { newPassword in
                barViewModel.updateBarPassword(currentBar, newPassword: newPassword)
            }
        }
        .sheet(isPresented: $showingEditSocialLinks) {
            EditSocialLinksView(
                socialLinks: $editingSocialLinks,
                barName: currentBar.name
            ) { newSocialLinks in
                barViewModel.updateBarSocialLinks(currentBar, newSocialLinks: newSocialLinks)
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(currentBar.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Show location prominently if available
                    if let location = currentBar.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(location.displayName)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 2)
                        
                        if !currentBar.address.isEmpty && currentBar.address != location.city {
                            Text(currentBar.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(currentBar.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Current status display
                VStack {
                    Image(systemName: currentBar.status.icon)
                        .font(.system(size: 40))
                        .foregroundColor(currentBar.status.color)
                    
                    Text(currentBar.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(currentBar.status.color)
                }
            }
            
            // Show status source information
            HStack(spacing: 8) {
                Image(systemName: currentBar.isFollowingSchedule ? "calendar" : "hand.raised.fill")
                    .foregroundColor(currentBar.isFollowingSchedule ? .green : .orange)
                    .font(.caption)
                
                if currentBar.isFollowingSchedule {
                    Text("Following schedule")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Manual override")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text("Updated \(timeAgo(currentBar.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            // Real-time auto-transition info (if active)
            if currentBar.isAutoTransitionActive, let pendingStatus = currentBar.pendingStatus {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("Will automatically change to \(pendingStatus.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let timeRemaining = barViewModel.getTimeRemainingText(for: currentBar) {
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
                StatusControlView(bar: currentBar, barViewModel: barViewModel)
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
                        editingOperatingHours = currentBar.operatingHours
                        showingEditOperatingHours = true
                    }
                    .font(.caption)
                }
            }
            
            // Today's hours (highlighted)
            let today = getCurrentWeekDay()
            let todayHours = currentBar.operatingHours.getDayHours(for: today)
            
            if todayHours.isOpen {
                HStack {
                    Text("Today (\(today.displayName)):")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(todayHours.displayText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                HStack {
                    Text("Today (\(today.displayName)):")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Closed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Schedule vs Reality notification for owners
            if isOwnerMode && !currentBar.isFollowingSchedule {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Manual Override Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Current status (\(currentBar.status.displayName)) differs from schedule (\(currentBar.scheduleBasedStatus.displayName))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // All week hours
            VStack(spacing: 4) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    let dayHours = currentBar.operatingHours.getDayHours(for: day)
                    let isToday = day == today
                    
                    HStack {
                        Text(day.displayName)
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundColor(isToday ? .primary : .secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Spacer()
                        
                        Text(dayHours.displayText)
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundColor(dayHours.isOpen ? (isToday ? .green : .primary) : .secondary)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    // Helper function to get current weekday
    private func getCurrentWeekDay() -> WeekDay {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        switch weekday {
        case 1: return WeekDay.sunday
        case 2: return WeekDay.monday
        case 3: return WeekDay.tuesday
        case 4: return WeekDay.wednesday
        case 5: return WeekDay.thursday
        case 6: return WeekDay.friday
        case 7: return WeekDay.saturday
        default: return WeekDay.monday
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
                        editingDescription = currentBar.description
                        showingEditDescription = true
                    }
                    .font(.caption)
                }
            }
            
            Text(currentBar.description.isEmpty ? "No description available." : currentBar.description)
                .font(.body)
                .foregroundColor(currentBar.description.isEmpty ? .secondary : .primary)
        }
    }
    
    // MARK: - Social Links Section
    var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Social Links")
                    .font(.headline)
                
                if isOwnerMode {
                    Spacer()
                    Button("Edit") {
                        editingSocialLinks = currentBar.socialLinks
                        showingEditSocialLinks = true
                    }
                    .font(.caption)
                }
            }
            
            if !currentBar.socialLinks.instagram.isEmpty ||
               !currentBar.socialLinks.twitter.isEmpty ||
               !currentBar.socialLinks.website.isEmpty ||
               !currentBar.socialLinks.facebook.isEmpty {
                
                SocialLinksView(socialLinks: currentBar.socialLinks)
            } else if isOwnerMode {
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
                        editingPassword = currentBar.password
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
    
    // MARK: - Helper Functions
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Simplified Supporting Views
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Social Links")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help customers find \(barName) online")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 20) {
                        SocialLinkEditor(
                            icon: "instagram-icon",
                            title: "Instagram",
                            placeholder: "https://instagram.com/yourbar",
                            text: $tempInstagram,
                            description: "Your Instagram profile or page",
                            isAssetImage: true
                        )
                        
                        SocialLinkEditor(
                            icon: "x-icon",
                            title: "X (Twitter)",
                            placeholder: "https://x.com/yourbar",
                            text: $tempTwitter,
                            description: "Your X (Twitter) profile or page",
                            isAssetImage: true
                        )
                        
                        SocialLinkEditor(
                            icon: "facebook-icon",
                            title: "Facebook",
                            placeholder: "https://facebook.com/yourbar",
                            text: $tempFacebook,
                            description: "Your Facebook page",
                            isAssetImage: true
                        )
                        
                        SocialLinkEditor(
                            icon: "globe",
                            title: "Website",
                            placeholder: "https://yourbar.com",
                            text: $tempWebsite,
                            description: "Your official website",
                            isAssetImage: false
                        )
                    }
                    
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
            tempInstagram = socialLinks.instagram
            tempTwitter = socialLinks.twitter
            tempFacebook = socialLinks.facebook
            tempWebsite = socialLinks.website
        }
    }
    
    private func saveSocialLinks() {
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
        
        if trimmed.isEmpty {
            return ""
        }
        
        if !trimmed.lowercased().hasPrefix("http://") && !trimmed.lowercased().hasPrefix("https://") {
            return "https://" + trimmed
        }
        
        return trimmed
    }
}

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

extension Text {
    func fontFamily(_ family: Font.Design) -> Text {
        self.font(.system(.caption, design: family))
    }
}
