import SwiftUI
import LocalAuthentication

// MARK: - Improved CreateBarView (Fixed Country/City Selection)
struct CreateBarView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Step 1: Essential Info
    @State private var barName = ""
    @State private var password = ""
    @State private var selectedCountry: Country?
    @State private var selectedCity: City?
    @State private var enableQuickAccess = false
    
    // Step 2: Optional Setup
    @State private var description = ""
    @State private var weeklySchedule = WeeklySchedule()
    @State private var useDefaultSchedule = true
    
    // UI State
    @State private var currentStep = 1
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // FIXED: Added sheet state variables for country/city pickers
    @State private var showingCountryPicker = false
    @State private var showingCityPicker = false
    @StateObject private var locationManager = LocationManager.shared
    
    var canProceedStep1: Bool {
        !barName.isEmpty && password.count == 4 && selectedCountry != nil && selectedCity != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (currentStep == 1 ? 0.5 : 1.0), height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal)
                
                if currentStep == 1 {
                    essentialInfoStep
                } else {
                    optionalSetupStep
                }
                
                // Navigation Buttons
                HStack {
                    if currentStep == 2 {
                        Button("Back") {
                            withAnimation {
                                currentStep = 1
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    if currentStep == 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep = 2
                                setupSmartDefaults()
                            }
                        }
                        .disabled(!canProceedStep1)
                        .foregroundColor(canProceedStep1 ? .blue : .gray)
                        .fontWeight(.semibold)
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
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .disabled(isCreating)
                        .padding()
                    }
                }
            }
            .navigationTitle("Create Bar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        // FIXED: Added sheet modifiers for country and city pickers
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerSheet(
                selectedCountry: $selectedCountry,
                selectedCity: $selectedCity,
                locationManager: locationManager
            )
        }
        .sheet(isPresented: $showingCityPicker) {
            if let country = selectedCountry {
                CityPickerSheet(
                    country: country,
                    selectedCity: $selectedCity,
                    locationManager: locationManager
                )
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
    
    // MARK: - Step 1: Essential Information
    var essentialInfoStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Let's get started!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Just the basics to create your bar profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    // Bar Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Bar Name")
                                .font(.headline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        TextField("Enter your bar name", text: $barName)
                            .textFieldStyle(CreateBarTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    // FIXED: Location Selection with proper button actions
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Location")
                                .font(.headline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        HStack(spacing: 12) {
                            // FIXED: Country button with working action
                            Button(action: {
                                showingCountryPicker = true
                            }) {
                                HStack {
                                    if let country = selectedCountry {
                                        Text(country.flag)
                                        Text(country.name)
                                            .foregroundColor(.primary)
                                    } else {
                                        Image(systemName: "globe")
                                            .foregroundColor(.gray)
                                        Text("Country")
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedCountry != nil ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // FIXED: City button with working action
                            Button(action: {
                                if selectedCountry != nil {
                                    showingCityPicker = true
                                }
                            }) {
                                HStack {
                                    if let city = selectedCity {
                                        Image(systemName: "building.2")
                                            .foregroundColor(.blue)
                                        Text(city.name)
                                            .foregroundColor(.primary)
                                    } else {
                                        Image(systemName: "building.2")
                                            .foregroundColor(.gray)
                                        Text("City")
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCountry != nil ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    selectedCity != nil ? Color.blue.opacity(0.3) :
                                                    selectedCountry != nil ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(selectedCountry == nil)
                        }
                        
                        // FIXED: Added selected location display
                        if let country = selectedCountry, let city = selectedCity {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(city.name), \(country.name)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("4-Digit Password")
                                .font(.headline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        SecureField("1234", text: $password)
                            .textFieldStyle(CreateBarTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: password) { _, newValue in
                                if newValue.count > 4 {
                                    password = String(newValue.prefix(4))
                                }
                            }
                    }
                    
                    // Quick Access (Simplified)
                    if barViewModel.canUseBiometricAuth {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Access")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Toggle(isOn: $enableQuickAccess) {
                                HStack {
                                    Image(systemName: "faceid")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Enable \(barViewModel.biometricAuthInfo.displayName)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("Skip password next time")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .toggleStyle(SwitchToggleStyle())
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Step 2: Optional Setup
    var optionalSetupStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Almost done!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("These are optional but help customers find you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .frame(height: 80)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("Tell customers what makes your bar special")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Schedule Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Opening Hours")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Button(action: { useDefaultSchedule = true }) {
                                    HStack {
                                        Image(systemName: useDefaultSchedule ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(useDefaultSchedule ? .blue : .gray)
                                        Text("Use typical bar hours (6 PM - 2 AM)")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            
                            HStack {
                                Button(action: { useDefaultSchedule = false }) {
                                    HStack {
                                        Image(systemName: !useDefaultSchedule ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(!useDefaultSchedule ? .blue : .gray)
                                        Text("I'll set custom hours")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                        
                        Text("You can always change these later in settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupSmartDefaults() {
        if useDefaultSchedule {
            // Set typical bar hours for all days
            var schedule = WeeklySchedule()
            for i in 0..<schedule.schedules.count {
                schedule.schedules[i].isOpen = true
                schedule.schedules[i].openTime = "18:00"  // 6 PM
                schedule.schedules[i].closeTime = "02:00"  // 2 AM
            }
            weeklySchedule = schedule
        }
    }
    
    private func createBar() {
        isCreating = true
        
        guard let selectedCountry = selectedCountry,
              let selectedCity = selectedCity else {
            alertMessage = "Please select a location"
            showingAlert = true
            isCreating = false
            return
        }
        
        let barLocation = BarLocation(
            country: selectedCountry.name,
            countryCode: selectedCountry.id,
            city: selectedCity.name
        )
        
        // Apply schedule based on user choice
        let finalSchedule: WeeklySchedule
        if useDefaultSchedule {
            finalSchedule = weeklySchedule
        } else {
            finalSchedule = WeeklySchedule() // Empty schedule, user will set later
        }
        
        let newBar = Bar(
            name: barName,
            address: selectedCity.name,
            description: description,
            username: barName,
            password: password,
            weeklySchedule: finalSchedule,
            location: barLocation
        )
        
        barViewModel.createNewBar(newBar, enableFaceID: enableQuickAccess) { success, message in
            DispatchQueue.main.async {
                isCreating = false
                alertMessage = message
                showingAlert = true
            }
        }
    }
}

// MARK: - Supporting Components (with unique names to avoid conflicts)

struct CreateBarTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    CreateBarView(barViewModel: BarViewModel())
}
