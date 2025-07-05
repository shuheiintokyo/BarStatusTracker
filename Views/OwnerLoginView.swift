import SwiftUI

struct OwnerLoginView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Binding var showingOwnerLogin: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Bar Owner Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("Bar Name", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .placeholder(when: username.isEmpty) {
                            Text("e.g., Sunset Tavern").foregroundColor(.gray)
                        }
                    
                    SecureField("4-Digit Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .placeholder(when: password.isEmpty) {
                            Text("Enter 4-digit code").foregroundColor(.gray)
                        }
                }
                .padding()
                
                Button(action: {
                    attemptLogin()
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((!username.isEmpty && !password.isEmpty) ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(username.isEmpty || password.isEmpty)
                .padding(.horizontal)
                
                // Show available bars for testing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Credentials:")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(barViewModel.getAllBars(), id: \.id) { bar in
                        Text("• \(bar.name) - Password: \(bar.password)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
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
    
    private func attemptLogin() {
        if barViewModel.authenticateBar(username: username, password: password) {
            showingOwnerLogin = false
            dismiss()
        } else {
            alertMessage = "Invalid bar name or password. Please check your credentials."
            showingAlert = true
        }
    }
}

// Helper extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
