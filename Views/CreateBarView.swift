import SwiftUI
import LocalAuthentication

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
    
    @State private var showingCountryPicker = false
    @State private var showingCityPicker = false
    @StateObject private var locationManager = LocationManager.shared
    
    var canProceedStep1: Bool {
        !barName.isEmpty && password.count == 4 && selectedCountry != nil && selectedCity != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar with Liquid Glass
                progressBarView
                
                if currentStep == 1 {
                    essentialInfoStep
                } else {
                    optionalSetupStep
                }
                
                // Navigation Buttons
                navigationButtonsView
            }
            .background(.regularMaterial)
            .onTapGesture {
                hideKeyboard()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Create Bar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        hideKeyboard()
                        dismiss()
                    }
                }
            }
        }
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
        .onAppear {
            enableSimulatorBiometrics()
        }
    }
    
    // MARK: - Progress Bar with Liquid Glass
    var progressBarView: some View {
        VStack(spacing: 12) {
            // Step indicator
            HStack {
                Text("Step \(currentStep) of 2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(currentStep == 1 ? "Essential Info" : "Optional Setup")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.tertiary)
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.blue)
                        .frame(width: geometry.size.width * progressValue, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 6)
        }
        .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
        .padding(.horizontal)
    }
    
    private var progressValue: CGFloat {
        currentStep == 1 ? 0.5 : 1.0
    }
    
    // MARK: - Step 1: Essential Information
    var essentialInfoStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                VStack(spacing: 20) {
                    // Bar Name
                    barNameSection
                    
                    // Location Selection
                    locationSection
                    
                    // Password
                    passwordSection
                    
                    // Quick Access
                    if barViewModel.canUseBiometricAuth {
                        quickAccessSection
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Step 1 Components
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Let's get started!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text("Just the basics to create your bar profile")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(level: .ultra, cornerRadius: .large, shadow: .subtle)
    }
    
    private var barNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bar Name")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("*")
                    .foregroundColor(.red)
            }
            
            TextField("Enter your bar name", text: $barName)
                .textFieldStyle(LiquidGlassTextFieldStyle())
                .autocapitalization(.words)
                .submitLabel(.next)
                .onSubmit {
                    hideKeyboard()
                }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("*")
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 12) {
                countryButton
                cityButton
            }
            
            // Selected location display
            if let country = selectedCountry, let city = selectedCity {
                selectedLocationDisplay(country: country, city: city)
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    private var countryButton: some View {
        Button(action: {
            hideKeyboard()
            showingCountryPicker = true
        }) {
            HStack {
                if let country = selectedCountry {
                    Text(country.flag)
                    Text(country.name)
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                    Text("Country")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
        }
        .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedCountry != nil ? .blue.opacity(0.3) : .clear, lineWidth: 1)
        )
    }
    
    private var cityButton: some View {
        Button(action: {
            hideKeyboard()
            if selectedCountry != nil {
                showingCityPicker = true
            }
        }) {
            HStack {
                if let city = selectedCity {
                    Image(systemName: "building.2")
                        .foregroundStyle(.primary)
                    Text(city.name)
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "building.2")
                        .foregroundStyle(.secondary)
                    Text("City")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
        }
        .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
        .disabled(selectedCountry == nil)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedCity != nil ? .blue.opacity(0.3) : .clear, lineWidth: 1)
        )
    }
    
    private func selectedLocationDisplay(country: Country, city: City) -> some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.green)
            Text("\(city.name), \(country.name)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("4-Digit Password")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("*")
                    .foregroundColor(.red)
            }
            
            SecureField("1234", text: $password)
                .textFieldStyle(LiquidGlassTextFieldStyle())
                .keyboardType(.numberPad)
                .submitLabel(.done)
                .onChange(of: password) { _, newValue in
                    if newValue.count > 4 {
                        password = String(newValue.prefix(4))
                    }
                    // Auto-dismiss keyboard when 4 digits entered
                    if newValue.count == 4 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            hideKeyboard()
                        }
                    }
                }
                .onSubmit {
                    hideKeyboard()
                }
            
            // Password validation feedback
            HStack {
                Image(systemName: password.count == 4 ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(password.count == 4 ? .green : .secondary)
                    .font(.caption)
                
                Text("Must be exactly 4 digits")
                    .font(.caption)
                    .foregroundColor(password.count == 4 ? .green : .secondary)
            }
            .animation(.easeInOut(duration: 0.2), value: password.count)
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Toggle(isOn: $enableQuickAccess) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable \(barViewModel.biometricAuthInfo.displayName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text("Skip password next time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle())
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Step 2: Optional Setup
    var optionalSetupStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                step2HeaderSection
                
                VStack(spacing: 20) {
                    descriptionSection
                    scheduleSection
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Step 2 Components
    private var step2HeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Almost done!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text("These are optional but help customers find you")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(level: .ultra, cornerRadius: .large, shadow: .subtle)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description (Optional)")
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextEditor(text: $description)
                .frame(height: 80)
                .padding(8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.primary.opacity(0.15), lineWidth: 0.5)
                )
                .onTapGesture {
                    // Allow text editor to get focus
                }
            
            Text("Tell customers what makes your bar special")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opening Hours")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                defaultScheduleOption
                customScheduleOption
            }
            .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
            
            Text("You can always change these later in settings")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    private var defaultScheduleOption: some View {
        HStack {
            Button(action: { useDefaultSchedule = true }) {
                HStack {
                    Image(systemName: useDefaultSchedule ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(useDefaultSchedule ? .blue : .secondary)
                    Text("Use typical bar hours (6 PM - 2 AM)")
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
    }
    
    private var customScheduleOption: some View {
        HStack {
            Button(action: { useDefaultSchedule = false }) {
                HStack {
                    Image(systemName: !useDefaultSchedule ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(!useDefaultSchedule ? .blue : .secondary)
                    Text("I'll set custom hours")
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
    }
    
    // MARK: - Navigation Buttons
    var navigationButtonsView: some View {
        HStack {
            if currentStep == 2 {
                Button("Back") {
                    hideKeyboard()
                    withAnimation {
                        currentStep = 1
                    }
                }
                .foregroundStyle(.primary)
                .padding()
            }
            
            Spacer()
            
            if currentStep == 1 {
                nextButton
            } else {
                createButton
            }
        }
    }
    
    private var nextButton: some View {
        Button("Next") {
            hideKeyboard()
            withAnimation {
                currentStep = 2
                setupSmartDefaults()
            }
        }
        .disabled(!canProceedStep1)
        .foregroundColor(canProceedStep1 ? .white : .secondary)
        .fontWeight(.semibold)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            canProceedStep1 ? .blue : .secondary.opacity(0.3),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .padding()
    }
    
    private var createButton: some View {
        Button(action: {
            hideKeyboard()
            createBar()
        }) {
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
                LinearGradient(
                    colors: [.green, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .opacity(0.2)
            )
        }
        .disabled(isCreating)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                       to: nil, from: nil, for: nil)
    }
    
    private func enableSimulatorBiometrics() {
        #if targetEnvironment(simulator)
        print("💡 To test biometric auth in simulator:")
        print("   Device > Face ID > Enrolled")
        #endif
    }
    
    private func setupSmartDefaults() {
        if useDefaultSchedule {
            var schedule = WeeklySchedule()
            for i in 0..<schedule.schedules.count {
                schedule.schedules[i].isOpen = true
                schedule.schedules[i].openTime = "18:00"
                schedule.schedules[i].closeTime = "02:00"
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
        
        let finalSchedule: WeeklySchedule
        if useDefaultSchedule {
            finalSchedule = weeklySchedule
        } else {
            finalSchedule = WeeklySchedule()
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
