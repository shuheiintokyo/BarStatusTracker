import SwiftUI

struct EditDescriptionView: View {
    @Binding var description: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section with liquid glass
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit Bar Description")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Tell customers what makes your bar special")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(level: .ultra, cornerRadius: .large, shadow: .subtle)
                    
                    // Text editor with liquid glass background
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        
                        TextEditor(text: $description)
                            .padding()
                            .frame(minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.primary.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        Text("Describe your bar's atmosphere, specialties, events, or anything that makes it unique...")
                                            .foregroundColor(.secondary)
                                            .padding()
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                        
                        Text("\(description.count) characters")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                    
                    // Tips section with liquid glass
                    VStack(alignment: .leading, spacing: 12) {
                        LiquidGlassSectionHeader("💡 Tips")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Tell customers about your bar's atmosphere and specialties")
                            TipRow(text: "Mention any special events or weekly features")
                            TipRow(text: "Your 7-day schedule shows when you're open")
                            TipRow(text: "Keep descriptions concise and engaging")
                            TipRow(text: "Highlight what makes your bar unique")
                            TipRow(text: "Consider mentioning signature drinks or food")
                        }
                    }
                    .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(.regularMaterial)
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
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Tip Row Component
struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.blue.opacity(0.3))
                .frame(width: 4, height: 4)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views for Password and Social Links Editing with Liquid Glass

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
            ScrollView {
                VStack(spacing: 24) {
                    // Header with liquid glass
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Change Password")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("for \(barName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Your password must be exactly 4 digits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(level: .ultra, cornerRadius: .large, shadow: .subtle)
                    
                    // Password fields with liquid glass
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.headline)
                            
                            HStack {
                                Text("••••")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.headline)
                            
                            SecureField("Enter new 4-digit password", text: $newPassword)
                                .textFieldStyle(LiquidGlassTextFieldStyle())
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
                                .textFieldStyle(LiquidGlassTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: confirmPassword) { _, newValue in
                                    if newValue.count > 4 {
                                        confirmPassword = String(newValue.prefix(4))
                                    }
                                }
                        }
                    }
                    .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                    
                    // Validation feedback with liquid glass
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password Requirements")
                            .font(.headline)
                        
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
                    .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(.regularMaterial)
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
                    .fontWeight(.semibold)
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
                    // Header with liquid glass
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Social Links")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("for \(barName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Help customers find you on social media")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(level: .ultra, cornerRadius: .large, shadow: .subtle)
                    
                    // Social link fields with liquid glass
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
                    .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                    
                    // Tips with liquid glass
                    VStack(alignment: .leading, spacing: 12) {
                        LiquidGlassSectionHeader("💡 Tips")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Don't include 'https://' - we'll add it automatically")
                            TipRow(text: "For Instagram/X, you can use just your username")
                            TipRow(text: "Social links help customers stay connected with your bar")
                            TipRow(text: "All fields are optional")
                        }
                    }
                    .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(.regularMaterial)
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
                    .fontWeight(.semibold)
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
                .textFieldStyle(LiquidGlassTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? .clear : .blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    EditDescriptionView(description: .constant("Sample bar description")) { _ in }
}
