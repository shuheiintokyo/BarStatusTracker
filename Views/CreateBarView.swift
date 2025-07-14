import SwiftUI

struct CreateBarView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Basic info
    @State private var barName = ""
    @State private var password = ""
    @State private var description = ""
    @State private var address = ""
    
    // 🌍 Location info (REQUIRED)
    @State private var selectedCountry: Country?
    @State private var selectedCity: City?
    
    // Operating hours
    @State private var operatingHours = OperatingHours()
    
    // Face ID option
    @State private var enableFaceIDLogin = false
    
    // UI state
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var currentPage = 0
    
    var canProceedToNextPage: Bool {
        switch currentPage {
        case 0: return !barName.isEmpty && password.count == 4 && selectedCountry != nil && selectedCity != nil
        case 1: return true // Operating hours is optional
        case 2: return true // Face ID is optional
        default: return false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator with NaN protection
                ProgressView(value: max(0.0, min(1.0, Double(currentPage + 1))), total: 3.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                TabView(selection: $currentPage) {
                    // Page 1: Basic Info + Location
                    basicInfoPage
                        .tag(0)
                    
                    // Page 2: Operating Hours
                    operatingHoursPage
                        .tag(1)
                    
                    // Page 3: Face ID & Final
                    finalPage
                        .tag(2)
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
                    
                    if currentPage < 2 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .disabled(!canProceedToNextPage)
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
                                canProceedToNextPage && !isCreating ? Color.green : Color.gray
                            )
                            .cornerRadius(10)
                        }
                        .disabled(!canProceedToNextPage || isCreating)
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
    
    // MARK: - Basic Info Page (UPDATED with Required Location)
    var basicInfoPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Basic Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your bar's essential details and location")
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
                    
                    // 🌍 Required: Location Selection
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
                
                // 🌍 Location importance note
                HStack {
                    Image(systemName: "location.circle")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why location matters:")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("• Helps customers find your bar easily")
                            .font(.caption2)
                        Text("• Distinguishes bars with similar names")
                            .font(.caption2)
                        Text("• Enables location-based search and browsing")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Operating Hours Page (Updated with Dual Slider)
    var operatingHoursPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operating Hours")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Set your regular operating days and hours (6 PM - 6 AM)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    ForEach(WeekDay.allCases, id: \.self) { day in
                        ImprovedDayHoursEditor(
                            day: day,
                            dayHours: Binding(
                                get: { operatingHours.getDayHours(for: day) },
                                set: { newValue in
                                    var updated = operatingHours
                                    updated.setDayHours(for: day, hours: newValue)
                                    operatingHours = updated
                                }
                            )
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Drag the green circles to set your opening and closing times")
                        Text("• Times are in 30-minute increments from 6 PM to 6 AM")
                        Text("• These are your regular hours for customer reference")
                        Text("• You can always update your real-time status in the app")
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
    }
    
    // MARK: - Final Page (UPDATED with Location Summary)
    var finalPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Almost Done!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Set up quick access and review your information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Face ID Setup
                if barViewModel.biometricAuthInfo.displayName != "Biometric" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Access Setup")
                            .font(.headline)
                        
                        Toggle(isOn: $enableFaceIDLogin) {
                            HStack {
                                Image(systemName: barViewModel.biometricAuthInfo.iconName)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
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
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(10)
                }
                
                // Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review Your Information")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Bar Name", value: barName)
                        InfoRow(label: "Password", value: "••••")
                        
                        // 🌍 Show selected location
                        if let country = selectedCountry, let city = selectedCity {
                            InfoRow(label: "Location", value: "\(city.name), \(country.name) \(country.flag)")
                        }
                        
                        if !address.isEmpty {
                            InfoRow(label: "Address", value: address)
                        }
                        
                        if !description.isEmpty {
                            InfoRow(label: "Description", value: String(description.prefix(50)) + (description.count > 50 ? "..." : ""))
                        }
                        
                        // Operating days summary
                        let openDays = WeekDay.allCases.filter { operatingHours.getDayHours(for: $0).isOpen }
                        if !openDays.isEmpty {
                            InfoRow(label: "Operating Days", value: openDays.map { $0.shortName }.joined(separator: ", "))
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Create Bar Function (UPDATED with Location)
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
        
        // 🌍 Create BarLocation object
        let barLocation = BarLocation(
            country: selectedCountry.name,
            countryCode: selectedCountry.id,
            city: selectedCity.name
        )
        
        // Create final address (combine street address with city if provided)
        let finalAddress = address.isEmpty ? selectedCity.name : address
        
        // Create new bar with location
        let newBar = Bar(
            name: barName,
            address: finalAddress,
            status: .closed,
            description: description,
            username: barName,
            password: password,
            operatingHours: operatingHours,
            location: barLocation
        )
        
        // Create bar in Firebase
        barViewModel.createNewBar(newBar, enableFaceID: enableFaceIDLogin) { success, message in
            DispatchQueue.main.async {
                isCreating = false
                alertMessage = message
                showingAlert = true
            }
        }
    }
}

// MARK: - Info Row
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
