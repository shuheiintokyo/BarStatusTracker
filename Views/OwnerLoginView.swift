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
    @State private var showingHelp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Clean Header
                VStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Bar Owner Access")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Manage your bar's status and settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Biometric Authentication (if available)
                if barViewModel.canUseBiometricAuth {
                    quickAccessSection
                }
                
                // Manual Login Section
                manualLoginSection
                
                Spacer()
                
                // Help button at bottom
                helpButton
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
        .alert("Login Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingHelp) {
            helpSheet
        }
    }
    
    // MARK: - Quick Access Section
    var quickAccessSection: some View {
        VStack(spacing: 16) {
            Text("Quick Access")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: authenticateWithBiometrics) {
                HStack(spacing: 12) {
                    Image(systemName: barViewModel.biometricAuthInfo.iconName)
                        .font(.title2)
                    Text("Login with \(barViewModel.biometricAuthInfo.displayName)")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .scaleEffect(isLoading ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isLoading)
            }
            .disabled(isLoading)
            
            // Clean divider
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
        }
    }
    
    // MARK: - Manual Login Section
    var manualLoginSection: some View {
        VStack(spacing: 20) {
            Text("Manual Login")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                // Bar Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bar Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    TextField("Enter your bar name", text: $username)
                        .textFieldStyle(CustomTextFieldStyle())
                        .autocapitalization(.words)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    SecureField("4-digit password", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: password) { _, newValue in
                            if newValue.count > 4 {
                                password = String(newValue.prefix(4))
                            }
                        }
                }
            }
            
            // Login Button
            Button(action: attemptLogin) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    Text(isLoading ? "Logging in..." : "Login")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    loginButtonBackground
                )
                .cornerRadius(16)
                .scaleEffect(isLoading ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isLoading)
            }
            .disabled(!canLogin || isLoading)
        }
    }
    
    // MARK: - Help Button
    var helpButton: some View {
        Button(action: { showingHelp = true }) {
            HStack {
                Image(systemName: "questionmark.circle")
                Text("Need Help?")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
    }
    
    // MARK: - Help Sheet
    var helpSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🏪 Bar Owner Login Help")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Having trouble logging in? Here's what you need to know:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        helpItem(
                            icon: "person.text.rectangle",
                            title: "Username",
                            description: "Use your exact bar name as the username"
                        )
                        
                        helpItem(
                            icon: "key.fill",
                            title: "Password",
                            description: "Enter the 4-digit code you set when creating your bar"
                        )
                        
                        helpItem(
                            icon: "plus.circle",
                            title: "New Bar Owner?",
                            description: "Tap 'Cancel' and create a new bar first"
                        )
                        
                        helpItem(
                            icon: "faceid",
                            title: "Quick Access",
                            description: "After first login, enable biometric authentication for faster access"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔒 Security Note")
                            .font(.headline)
                        
                        Text("For security reasons, we don't display passwords on screen. If you've forgotten your credentials, you may need to create a new bar profile.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingHelp = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func helpItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var canLogin: Bool {
        !username.isEmpty && password.count == 4
    }
    
    private var loginButtonBackground: some View {
        Group {
            if canLogin && !isLoading {
                LinearGradient(
                    gradient: Gradient(colors: [.green, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                Color.gray.opacity(0.3)
            }
        }
    }
    
    // MARK: - Methods
    
    private func attemptLogin() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if barViewModel.authenticateBar(username: username, password: password) {
                showingOwnerLogin = false
                dismiss()
            } else {
                alertMessage = "Invalid credentials. Please check your bar name and password."
                showingAlert = true
            }
            isLoading = false
        }
    }
    
    private func authenticateWithBiometrics() {
        isLoading = true
        
        barViewModel.authenticateWithBiometrics { success, error in
            isLoading = false
            
            if success {
                showingOwnerLogin = false
                dismiss()
            } else {
                alertMessage = error ?? "Authentication failed"
                showingAlert = true
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

