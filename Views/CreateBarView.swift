import SwiftUI
import LocalAuthentication

struct CreateBarView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Page 1: Basic info + FaceID
    @State private var barName = ""
    @State private var password = ""
    @State private var enableFaceIDLogin = false
    
    // Page 2: Location info
    @State private var selectedCountry: Country?
    @State private var selectedCity: City?
    @State private var address = ""
    @State private var description = ""
    
    // Page 3: 7-day schedule
    @State private var weeklySchedule = WeeklySchedule()
    
    // UI state
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var currentPage = 0
    
    // ENHANCED: Biometric testing state
    @State private var isTestingBiometric = false
    @State private var biometricTestResult: BiometricTestResult?
    
    enum BiometricTestResult {
        case success
        case failed
    }
    
    var canProceedFromPage: Bool {
        switch currentPage {
        case 0: return !barName.isEmpty && password.count == 4
        case 1: return selectedCountry != nil && selectedCity != nil
        case 2: return true // Schedule is optional
        case 3: return true // Confirmation page
        default: return false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: max(0.0, min(1.0, Double(currentPage + 1))), total: 4.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                TabView(selection: $currentPage) {
                    // Page 1: Basic Info + FaceID
                    basicInfoAndFaceIDPage
                        .tag(0)
                    
                    // Page 2: Location Info
                    locationInfoPage
                        .tag(1)
                    
                    // Page 3: 7-Day Schedule
                    scheduleSetupPage
                        .tag(2)
                    
                    // Page 4: Confirmation
                    confirmationPage
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    if currentPage < 3 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .disabled(!canProceedFromPage)
                        .padding()
                    } else {
                        Button(action: createBar) {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isCreating ? "Creating..." : "Create Bar")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                canProceedFromPage && !isCreating ? Color.green : Color.gray
                            )
                            .cornerRadius(10)
                        }
                        .disabled(!canProceedFromPage || isCreating)
                        .padding()
                    }
                }
            }
            .navigationTitle("Create New Bar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Bar Creation", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Page 1: Basic Info + ENHANCED FaceID
    var basicInfoAndFaceIDPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Basic Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your bar's name and login credentials")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    // Required: Bar Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Bar Name")
                                .font(.headline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        TextField("Enter your bar name", text: $barName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                        
                        Text("This will also be your login username")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Required: Password
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("4-Digit Password")
                                .font(.headline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        SecureField("Enter 4-digit password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: password) { oldValue, newValue in
                                if newValue.count > 4 {
                                    password = String(newValue.prefix(4))
                                }
                            }
                        
                        Text("Used for logging in to manage your bar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // ENHANCED: FaceID Setup with actual testing
                    if barViewModel.biometricAuthInfo.displayName != "Biometric" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Access (Optional)")
                                .font(.headline)
                            
                            VStack(spacing: 16) {
                                Toggle(isOn: $enableFaceIDLogin) {
                                    HStack {
                                        Image(systemName: barViewModel.biometricAuthInfo.iconName)
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Enable \(barViewModel.biometricAuthInfo.displayName)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Text("Quick login without entering password")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle())
                                .onChange(of: enableFaceIDLogin) { _, newValue in
                                    if !newValue {
                                        // Reset test result when disabled
                                        biometricTestResult = nil
                                    }
                                }
                                
                                // NEW: Test Face ID when enabled
                                if enableFaceIDLogin {
                                    Button(action: testBiometricAuth) {
                                        HStack {
                                            if isTestingBiometric {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: biometricTestResult == .success ? "checkmark.circle.fill" : barViewModel.biometricAuthInfo.iconName)
                                            }
                                            
                                            Text(isTestingBiometric ? "Testing..." : "Test \(barViewModel.biometricAuthInfo.displayName)")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(biometricTestResult == .success ? Color.green : Color.blue)
                                        .cornerRadius(10)
                                    }
                                    .disabled(isTestingBiometric)
                                    
                                    // Show test result
                                    if let result = biometricTestResult {
                                        HStack {
                                            Image(systemName: result == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                                .foregroundColor(result == .success ? .green : .orange)
                                            
                                            Text(result == .success ?
                                                 "\(barViewModel.biometricAuthInfo.displayName) is working!" :
                                                 "Please enable \(barViewModel.biometricAuthInfo.displayName) in Settings")
                                                .font(.caption)
                                                .foregroundColor(result == .success ? .green : .orange)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Required fields note
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("* Required fields")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Page 2: Location Info
    var locationInfoPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Help customers find your bar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    // Required: Location Selection
                    LocationPicker(
                        selectedCountry: $selectedCountry,
                        selectedCity: $selectedCity
                    )
                    
                    // Optional: Street Address
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Street Address (Optional)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter street address", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                        
                        Text("Specific street address within the selected city")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Optional: Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        
                        Text("Tell customers about your bar, specials, atmosphere, etc.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Page 3: 7-Day Schedule Setup
    var scheduleSetupPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("7-Day Schedule")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Set your opening hours for the next 7 days starting from today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Calendar-style schedule editor
                VStack(spacing: 16) {
                    ForEach(Array(weeklySchedule.schedules.enumerated()), id: \.element.id) { index, schedule in
                        DailyScheduleEditor(
                            schedule: Binding(
                                get: { weeklySchedule.schedules[index] },
                                set: { weeklySchedule.schedules[index] = $0 }
                            )
                        )
                    }
                }
                
                // Tips section
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Today's schedule will determine your current bar status")
                        Text("• Drag the time sliders to set your opening and closing times")
                        Text("• Times are in 30-minute increments from 6 PM to 6 AM")
                        Text("• You can always update your schedule later in the app")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(10)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Page 4: Confirmation
    var confirmationPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review & Confirm")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Review your information before creating your bar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Summary sections
                VStack(spacing: 16) {
                    // Basic Info
                    SummarySection(title: "Basic Information") {
                        InfoRow(label: "Bar Name", value: barName)
                        InfoRow(label: "Password", value: "••••")
                        InfoRow(label: "Quick Access", value: enableFaceIDLogin ?
                                (biometricTestResult == .success ?
                                 "✅ \(barViewModel.biometricAuthInfo.displayName) Enabled" :
                                 "⚠️ \(barViewModel.biometricAuthInfo.displayName) (Not Tested)") :
                                "Manual login only")
                    }
                    
                    // Location Info
                    SummarySection(title: "Location") {
                        if let country = selectedCountry, let city = selectedCity {
                            InfoRow(label: "Location", value: "\(city.name), \(country.name) \(country.flag)")
                        }
                        
                        if !address.isEmpty {
                            InfoRow(label: "Address", value: address)
                        }
                        
                        if !description.isEmpty {
                            InfoRow(label: "Description", value: String(description.prefix(50)) + (description.count > 50 ? "..." : ""))
                        }
                    }
                    
                    // Schedule Summary
                    SummarySection(title: "7-Day Schedule") {
                        ForEach(weeklySchedule.schedules) { schedule in
                            InfoRow(
                                label: "\(schedule.shortDayName) \(schedule.displayDate)",
                                value: schedule.displayText
                            )
                        }
                    }
                }
                
                // ENHANCED: Biometric setup warning if enabled but not tested
                if enableFaceIDLogin && biometricTestResult != .success {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Biometric Setup Incomplete")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Text("\(barViewModel.biometricAuthInfo.displayName) is enabled but hasn't been tested successfully. You may need to set it up manually after creating your bar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Test Now") {
                            testBiometricAuth()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - ENHANCED: Biometric Test Method
    private func testBiometricAuth() {
        isTestingBiometric = true
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricTestResult = .failed
            isTestingBiometric = false
            return
        }
        
        let reason = "Test \(barViewModel.biometricAuthInfo.displayName) for bar access"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                isTestingBiometric = false
                biometricTestResult = success ? .success : .failed
                
                if !success {
                    // If test fails, disable the toggle
                    enableFaceIDLogin = false
                }
            }
        }
    }
    
    // MARK: - Create Bar Function
    private func createBar() {
        isCreating = true
        
        // Validate required fields
        guard !barName.isEmpty,
              password.count == 4,
              let selectedCountry = selectedCountry,
              let selectedCity = selectedCity else {
            alertMessage = "Please fill in all required fields (Bar Name, Password, and Location)"
            showingAlert = true
            isCreating = false
            return
        }
        
        // Check if bar name already exists
        if barViewModel.getAllBars().contains(where: { $0.name.lowercased() == barName.lowercased() }) {
            alertMessage = "A bar with this name already exists. Please choose a different name."
            showingAlert = true
            isCreating = false
            return
        }
        
        // ENHANCED: Only enable Face ID if it was successfully tested
        let finalEnableFaceID = enableFaceIDLogin && biometricTestResult == .success
        
        // Create BarLocation object
        let barLocation = BarLocation(
            country: selectedCountry.name,
            countryCode: selectedCountry.id,
            city: selectedCity.name
        )
        
        // Create final address
        let finalAddress = address.isEmpty ? selectedCity.name : address
        
        // Create new bar with 7-day schedule
        let newBar = Bar(
            name: barName,
            address: finalAddress,
            description: description,
            username: barName,
            password: password,
            weeklySchedule: weeklySchedule,
            location: barLocation
        )
        
        // Create bar in Firebase
        barViewModel.createNewBar(newBar, enableFaceID: finalEnableFaceID) { success, message in
            DispatchQueue.main.async {
                isCreating = false
                alertMessage = message
                showingAlert = true
            }
        }
    }
}

// MARK: - Summary Section Component
struct SummarySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

#Preview {
    CreateBarView(barViewModel: BarViewModel())
}
