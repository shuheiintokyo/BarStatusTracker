import SwiftUI
import CoreLocation

struct CreateBarView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Basic info
    @State private var barName = ""
    @State private var password = ""
    @State private var description = ""
    @State private var address = ""
    
    // Location
    @State private var latitude: Double = 35.6762 // Default to Tokyo
    @State private var longitude: Double = 139.6503
    
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
        case 0: return !barName.isEmpty && password.count == 4 && !address.isEmpty
        case 1: return true // Operating hours is optional
        case 2: return true // Face ID is optional
        default: return false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentPage + 1), total: 3.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                TabView(selection: $currentPage) {
                    // Page 1: Basic Info
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
    
    // MARK: - Basic Info Page
    var basicInfoPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Basic Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your bar's basic details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bar Name")
                            .font(.headline)
                        
                        TextField("Enter your bar name", text: $barName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                        
                        Text("This will also be your login username")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("4-Digit Password")
                            .font(.headline)
                        
                        SecureField("Enter 4-digit password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: password) { _, newValue in
                                if newValue.count > 4 {
                                    password = String(newValue.prefix(4))
                                }
                            }
                        
                        Text("Used for logging in to manage your bar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address")
                            .font(.headline)
                        
                        TextField("Enter your bar's address", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                        
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
    
    // MARK: - Operating Hours Page
    var operatingHoursPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operating Hours")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Set your regular operating days and hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    ForEach(WeekDay.allCases, id: \.self) { day in
                        DayHoursEditor(
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
                    
                    Text("• These are your regular hours for customer reference\n• You can always update your real-time status in the app\n• Hours can span overnight (e.g., 6 PM to 2 AM)")
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
    
    // MARK: - Final Page
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
                        InfoRow(label: "Address", value: address)
                        InfoRow(label: "Password", value: "••••")
                        
                        if !description.isEmpty {
                            InfoRow(label: "Description", value: description.prefix(50) + (description.count > 50 ? "..." : ""))
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
    
    // MARK: - Create Bar Function
    private func createBar() {
        isCreating = true
        
        // Validate required fields
        guard !barName.isEmpty, password.count == 4, !address.isEmpty else {
            alertMessage = "Please fill in all required fields"
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
        
        // Create new bar
        let newBar = Bar(
            name: barName,
            latitude: latitude,
            longitude: longitude,
            address: address,
            status: .closed,
            description: description,
            username: barName,
            password: password,
            operatingHours: operatingHours
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

// MARK: - Day Hours Editor
struct DayHoursEditor: View {
    let day: WeekDay
    @Binding var dayHours: DayHours
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .leading)
                
                Spacer()
                
                Toggle("", isOn: $dayHours.isOpen)
                    .labelsHidden()
            }
            
            if dayHours.isOpen {
                VStack(spacing: 12) {
                    // Open time
                    HStack {
                        Text("Opens:")
                            .font(.caption)
                            .frame(width: 50, alignment: .leading)
                        
                        TimeSlider(
                            time: Binding(
                                get: { dayHours.openTime },
                                set: { dayHours.openTime = $0 }
                            ),
                            range: 18...23 // 6 PM to 11 PM
                        )
                    }
                    
                    // Close time
                    HStack {
                        Text("Closes:")
                            .font(.caption)
                            .frame(width: 50, alignment: .leading)
                        
                        TimeSlider(
                            time: Binding(
                                get: { dayHours.closeTime },
                                set: { dayHours.closeTime = $0 }
                            ),
                            range: 0...6 // 12 AM to 6 AM next day
                        )
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding()
        .background(dayHours.isOpen ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Time Slider
struct TimeSlider: View {
    @Binding var time: String
    let range: ClosedRange<Int>
    
    private var hourValue: Int {
        get {
            let components = time.split(separator: ":")
            return Int(components.first ?? "18") ?? 18
        }
        set {
            time = String(format: "%02d:00", newValue)
        }
    }
    
    var body: some View {
        HStack {
            Slider(
                value: Binding(
                    get: { Double(hourValue) },
                    set: { hourValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            
            Text(formatTime(hour: hourValue))
                .font(.caption)
                .frame(width: 60, alignment: .trailing)
        }
    }
    
    private func formatTime(hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
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

