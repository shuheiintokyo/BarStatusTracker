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
            // Using gradient for create bar
            StylishBackgroundView(
                gradientName: "create_bar"
            ) {
                VStack(spacing: 0) {
                    // Progress Bar with glass effect
                    progressBarView
                    
                    if currentStep == 1 {
                        essentialInfoStep
                    } else {
                        optionalSetupStep
                    }
                    
                    // Navigation Buttons
                    navigationButtonsView
                }
                // Keyboard handling improvements
                .onTapGesture {
                    hideKeyboard()
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle("Create Bar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        hideKeyboard()
                        dismiss()
                    }
                    .foregroundColor(.white)
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
    
    // MARK: - Progress Bar with Glass Effect
    var progressBarView: some View {
        VStack(spacing: 12) {
            // Step indicator
            HStack {
                Text("Step \(currentStep) of 2")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(currentStep == 1 ? "Essential Info" : "Optional Setup")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            // Progress bar - separated for better type inference
            progressBar
        }
        .padding()
        .background(progressBarBackground)
        .padding(.horizontal)
    }
    
    // MARK: - Progress Bar Components
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 6)
                
                // Progress
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progressValue, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 6)
    }
    
    private var progressBarBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.thinMaterial)
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
                .foregroundColor(.white)
            
            Text("Just the basics to create your bar profile")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(headerBackground)
    }
    
    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
    }
    
    private var barNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bar Name")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("*")
                    .foregroundColor(.red)
            }
            
            TextField("Enter your bar name", text: $barName)
                .textFieldStyle(ImprovedGlassCreateBarTextFieldStyle())
                .autocapitalization(.words)
                .submitLabel(.next)
                .onSubmit {
                    hideKeyboard()
                }
        }
        .padding()
        .background(sectionBackground)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location")
                    .font(.headline)
                    .foregroundColor(.white)
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
        .padding()
        .background(sectionBackground)
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
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "globe")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Country")
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            .padding()
            .background(buttonBackground(isSelected: selectedCountry != nil))
        }
        .buttonStyle(PlainButtonStyle())
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
                        .foregroundColor(.white)
                    Text(city.name)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "building.2")
                        .foregroundColor(.white.opacity(0.7))
                    Text("City")
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            .padding()
            .background(buttonBackground(isSelected: selectedCity != nil, isEnabled: selectedCountry != nil))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedCountry == nil)
    }
    
    private func buttonBackground(isSelected: Bool, isEnabled: Bool = true) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isEnabled ? .thinMaterial : .thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
    }
    
    private func selectedLocationDisplay(country: Country, city: City) -> some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.green)
            Text("\(city.name), \(country.name)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(selectedLocationBackground)
    }
    
    private var selectedLocationBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.green.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.4), lineWidth: 1)
            )
    }
    
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("4-Digit Password")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("*")
                    .foregroundColor(.red)
            }
            
            SecureField("1234", text: $password)
                .textFieldStyle(ImprovedGlassCreateBarTextFieldStyle())
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
                    .foregroundColor(password.count == 4 ? .green : .white.opacity(0.6))
                    .font(.caption)
                
                Text("Must be exactly 4 digits")
                    .font(.caption)
                    .foregroundColor(password.count == 4 ? .green : .white.opacity(0.8))
            }
            .animation(.easeInOut(duration: 0.2), value: password.count)
        }
        .padding()
        .background(sectionBackground)
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            Toggle(isOn: $enableQuickAccess) {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(.white)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable \(barViewModel.biometricAuthInfo.displayName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Skip password next time")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle())
        }
        .padding()
        .background(sectionBackground)
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
                .foregroundColor(.white)
            
            Text("These are optional but help customers find you")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(headerBackground)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description (Optional)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            TextEditor(text: $description)
                .frame(height: 80)
                .padding(8)
                .background(textEditorBackground)
                .foregroundColor(.white)
                .onTapGesture {
                    // Allow text editor to get focus
                }
            
            Text("Tell customers what makes your bar special")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(sectionBackground)
    }
    
    private var textEditorBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opening Hours")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                defaultScheduleOption
                customScheduleOption
            }
            .padding()
            .background(scheduleOptionsBackground)
            
            Text("You can always change these later in settings")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(sectionBackground)
    }
    
    private var defaultScheduleOption: some View {
        HStack {
            Button(action: { useDefaultSchedule = true }) {
                HStack {
                    Image(systemName: useDefaultSchedule ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(useDefaultSchedule ? .blue : .white.opacity(0.7))
                    Text("Use typical bar hours (6 PM - 2 AM)")
                        .foregroundColor(.white)
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
                        .foregroundColor(!useDefaultSchedule ? .blue : .white.opacity(0.7))
                    Text("I'll set custom hours")
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
    }
    
    private var scheduleOptionsBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.thinMaterial)
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
                .foregroundColor(.white)
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
        .foregroundColor(canProceedStep1 ? .white : .white.opacity(0.5))
        .fontWeight(.semibold)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(nextButtonBackground)
        .padding()
    }
    
    private var nextButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(canProceedStep1 ? .thinMaterial : .thinMaterial)
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
            .background(createButtonBackground)
        }
        .disabled(isCreating)
        .padding()
    }
    
    private var createButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.green.opacity(0.8), .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .opacity(0.3)
            )
    }
    
    // MARK: - Common Styles
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.regularMaterial)
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

// MARK: - Improved Text Field Style with Keyboard Handling

struct ImprovedGlassCreateBarTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(textFieldBackground)
            .foregroundColor(.white)
            .onSubmit {
                // Automatically dismiss keyboard on submit
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                               to: nil, from: nil, for: nil)
            }
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Legacy Text Field Style (for compatibility)

struct GlassCreateBarTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(textFieldBackground)
            .foregroundColor(.white)
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}
