import SwiftUI

struct EditDescriptionView: View {
    @Binding var description: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $description)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding()
                
                // UPDATED: Tips section for 7-day schedule system
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Tell customers about your bar's atmosphere and specialties")
                        Text("• Mention any special events or weekly features")
                        Text("• Your 7-day schedule shows when you're open")  // UPDATED
                        Text("• Keep descriptions concise and engaging")
                        Text("• Highlight what makes your bar unique")
                        Text("• Consider mentioning signature drinks or food")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Edit Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(description)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views for Password and Social Links Editing

struct EditPasswordView: View {
    let currentPassword: String
    let barName: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var isValidPassword: Bool {
        newPassword.count == 4 && newPassword == confirmPassword && newPassword != currentPassword
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Change Password for \(barName)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your password must be exactly 4 digits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.headline)
                        
                        Text("••••")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.headline)
                        
                        SecureField("Enter new 4-digit password", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: newPassword) { _, newValue in
                                if newValue.count > 4 {
                                    newPassword = String(newValue.prefix(4))
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.headline)
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: confirmPassword) { _, newValue in
                                if newValue.count > 4 {
                                    confirmPassword = String(newValue.prefix(4))
                                }
                            }
                    }
                }
                
                // Validation feedback
                VStack(alignment: .leading, spacing: 8) {
                    ValidationRow(
                        text: "Password is 4 digits",
                        isValid: newPassword.count == 4
                    )
                    
                    ValidationRow(
                        text: "Passwords match",
                        isValid: !confirmPassword.isEmpty && newPassword == confirmPassword
                    )
                    
                    ValidationRow(
                        text: "Different from current password",
                        isValid: !newPassword.isEmpty && newPassword != currentPassword
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if isValidPassword {
                            onSave(newPassword)
                            dismiss()
                        } else {
                            alertMessage = "Please ensure your new password is 4 digits, matches the confirmation, and is different from your current password."
                            showingAlert = true
                        }
                    }
                    .disabled(!isValidPassword)
                }
            }
        }
        .alert("Invalid Password", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct ValidationRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary)
            
            Spacer()
        }
    }
}

struct EditSocialLinksView: View {
    @Binding var socialLinks: SocialLinks
    let barName: String
    let onSave: (SocialLinks) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Social Links for \(barName)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help customers find you on social media")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 20) {
                        SocialLinkField(
                            icon: "instagram-icon",
                            title: "Instagram",
                            placeholder: "@yourbarnamehere",
                            text: $socialLinks.instagram,
                            isAssetImage: true
                        )
                        
                        SocialLinkField(
                            icon: "x-icon",
                            title: "X (Twitter)",
                            placeholder: "@yourbarnamehere",
                            text: $socialLinks.twitter,
                            isAssetImage: true
                        )
                        
                        SocialLinkField(
                            icon: "facebook-icon",
                            title: "Facebook",
                            placeholder: "facebook.com/yourbarname",
                            text: $socialLinks.facebook,
                            isAssetImage: true
                        )
                        
                        SocialLinkField(
                            icon: "globe",
                            title: "Website",
                            placeholder: "www.yourbarname.com",
                            text: $socialLinks.website,
                            isAssetImage: false
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Tips")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Don't include 'https://' - we'll add it automatically")
                            Text("• For Instagram/X, you can use just your username")
                            Text("• Social links help customers stay connected with your bar")
                            Text("• All fields are optional")
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
            .navigationTitle("Social Links")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(socialLinks)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SocialLinkField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let isAssetImage: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Icon
                if isAssetImage {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if !text.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(text.isEmpty ? Color.gray.opacity(0.05) : Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? Color.gray.opacity(0.2) : Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    EditDescriptionView(description: .constant("Sample bar description")) { _ in }
}
