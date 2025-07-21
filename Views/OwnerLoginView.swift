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
    @State private var showPasswordRequirements = false

    // Animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    var canLogin: Bool {
        !username.isEmpty && password.count == 4
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header section with animation
                        VStack(spacing: 24) {
                            Spacer(minLength: 40)
                            
                            // Animated logo
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(logoScale)
                                .onAppear {
                                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                        logoScale = 1.0
                                    }
                                    withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                                        contentOpacity = 1.0
                                    }
                                }
                            
                            VStack(spacing: 8) {
                                Text("Welcome Back!")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Sign in to manage your bar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .opacity(contentOpacity)
                        }
                        .frame(minHeight: geometry.size.height * 0.3)
                        
                        // Login form
                        VStack(spacing: 24) {
                            loginFormSection
                            
                            // Quick access section (if available)
                            if barViewModel.canUseBiometricAuth {
                                quickAccessSection
                            }
                            
                            // Help section
                            helpSection
                        }
                        .opacity(contentOpacity)
                        .padding(.horizontal)
                        .frame(minHeight: geometry.size.height * 0.7)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Sign In", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Login Form Section
    var loginFormSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                // Bar Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bar Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter your bar name", text: $username)
                        .textFieldStyle(ModernLoginTextFieldStyle())
                        .autocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: { showPasswordRequirements.toggle() }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    SecureField("4-digit password", text: $password)
                        .textFieldStyle(ModernLoginTextFieldStyle())
                        .keyboardType(.numberPad)
                        .submitLabel(.go)
                        .onChange(of: password) { _, newValue in
                            if newValue.count > 4 {
                                password = String(newValue.prefix(4))
                            }
                        }
                        .onSubmit {
                            if canLogin {
                                attemptLogin()
                            }
                        }
                    
                    // Password validation feedback
                    HStack {
                        Image(systemName: password.count == 4 ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(password.count == 4 ? .green : .gray)
                            .font(.caption)
                        
                        Text("Must be exactly 4 digits")
                            .font(.caption)
                            .foregroundColor(password.count == 4 ? .green : .secondary)
                    }
                    .animation(.easeInOut(duration: 0.2), value: password.count)
                    
                    // Password requirements (expandable)
                    if showPasswordRequirements {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password Requirements:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            Text("• Must be exactly 4 digits (0-9)")
                            Text("• Set when you created your bar")
                            Text("• Contact support if forgotten")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
                    
                    Text(isLoading ? "Signing in..." : "Sign In")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            canLogin && !isLoading ?
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .scaleEffect(isLoading ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isLoading)
            }
            .disabled(!canLogin || isLoading)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Quick Access Section
    var quickAccessSection: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            
            Button(action: authenticateWithBiometrics) {
                HStack(spacing: 12) {
                    Image(systemName: barViewModel.biometricAuthInfo.iconName)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Access")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Use \(barViewModel.biometricAuthInfo.displayName) to sign in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
        }
    }

    // MARK: - Help Section
    var helpSection: some View {
        VStack(spacing: 12) {
            Text("Need Help?")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                helpButton(
                    title: "New bar owner?",
                    subtitle: "Create your bar first",
                    action: { dismiss() }
                )
                
                helpButton(
                    title: "Forgot your password?",
                    subtitle: "Contact support for assistance",
                    action: { /* Handle forgot password */ }
                )
            }
        }
        .padding(.top, 8)
    }

    private func helpButton(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Methods

    private func attemptLogin() {
        guard canLogin else { return }
        
        isLoading = true
        
        // Add slight delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if barViewModel.authenticateBar(username: username, password: password) {
                // Success animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    logoScale = 1.1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showingOwnerLogin = false
                    dismiss()
                }
            } else {
                // Shake animation for error
                withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                    logoScale = 0.95
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        logoScale = 1.0
                    }
                }
                
                alertMessage = "Invalid bar name or password. Please try again."
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
