import SwiftUI

struct OwnerLoginView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Binding var showingOwnerLogin: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    @State private var barToDelete: Bar?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Bar Owner Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Access your bar's control panel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Biometric Authentication Section (if available)
                if barViewModel.canUseBiometricAuth {
                    VStack(spacing: 16) {
                        Text("Quick Access")
                            .font(.headline)
                        
                        Button(action: {
                            authenticateWithBiometrics()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: barViewModel.biometricAuthInfo.iconName)
                                    .font(.title2)
                                Text("Login with \(barViewModel.biometricAuthInfo.displayName)")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Traditional Login Section
                VStack(spacing: 16) {
                    Text(barViewModel.canUseBiometricAuth ? "Manual Login" : "Login with Credentials")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        TextField("Bar Name", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .overlay(
                                HStack {
                                    Spacer()
                                    if !username.isEmpty {
                                        Button(action: { username = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.trailing, 8)
                                    }
                                }
                            )
                        
                        SecureField("4-Digit Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: password) { _, newValue in
                                // Limit to 4 digits
                                if newValue.count > 4 {
                                    password = String(newValue.prefix(4))
                                }
                            }
                    }
                    
                    Button(action: {
                        attemptTraditionalLogin()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Logging in..." : "Login")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (!username.isEmpty && password.count == 4 && !isLoading) ?
                            Color.green : Color.gray
                        )
                        .cornerRadius(10)
                    }
                    .disabled(username.isEmpty || password.count != 4 || isLoading)
                }
                
                // Delete Bar Section (for existing bars)
                if !barViewModel.getAllBars().isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Bar Management")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Text("If you own a bar and want to remove it from the app:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(barViewModel.getAllBars(), id: \.id) { bar in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(bar.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("Password: \(bar.password)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .fontFamily(.monospaced)
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Delete") {
                                            barToDelete = bar
                                            showingDeleteConfirmation = true
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.red)
                                        .cornerRadius(6)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Test Credentials Section (only show sample bars)
                let sampleBars = barViewModel.getAllBars().filter {
                    ["The Cozy Corner", "Sunset Tavern", "The Underground"].contains($0.name)
                }
                
                if !sampleBars.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Credentials (Sample Bars):")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(sampleBars, id: \.id) { bar in
                                    HStack {
                                        Text("• \(bar.name)")
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("Password: \(bar.password)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fontFamily(.monospaced)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(maxHeight: 80)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Login Failed", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Delete Bar", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                barToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let bar = barToDelete {
                    deleteBar(bar)
                }
            }
        } message: {
            if let bar = barToDelete {
                Text("Are you sure you want to permanently delete '\(bar.name)'? This action cannot be undone. All customer favorites and data will be lost.")
            }
        }
    }
    
    // Traditional login
    private func attemptTraditionalLogin() {
        isLoading = true
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if barViewModel.authenticateBar(username: username, password: password) {
                showingOwnerLogin = false
                dismiss()
            } else {
                alertMessage = "Invalid bar name or password. Please check your credentials."
                showingAlert = true
            }
            isLoading = false
        }
    }
    
    // Biometric authentication
    private func authenticateWithBiometrics() {
        isLoading = true
        
        barViewModel.authenticateWithBiometrics { success, error in
            isLoading = false
            
            if success {
                showingOwnerLogin = false
                dismiss()
            } else {
                alertMessage = error ?? "Biometric authentication failed"
                showingAlert = true
            }
        }
    }
    
    // Delete bar
    private func deleteBar(_ bar: Bar) {
        barViewModel.deleteBar(bar) { success, message in
            DispatchQueue.main.async {
                alertMessage = message
                showingAlert = true
                barToDelete = nil
                
                if success {
                    // If we successfully deleted the bar, dismiss the login view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
    }
}

//// Helper extension for monospaced font
//extension Text {
//    func fontFamily(_ family: Font.Design) -> Text {
//        self.font(.system(.caption, design: family))
//    }
//}
