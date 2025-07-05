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
                            .onChange(of: password) { newValue in
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
                
                // Test Credentials Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Credentials:")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(barViewModel.getAllBars(), id: \.id) { bar in
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
                    .frame(maxHeight: 120)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
                .border(Color.blue.opacity(0.2), width: 1)
                
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
}

// Helper extension for monospaced font
extension Text {
    func fontFamily(_ family: Font.Design) -> Text {
        self.font(.system(.caption, design: family))
    }
}
