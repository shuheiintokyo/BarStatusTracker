import LocalAuthentication
import Security
import Foundation

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var savedBarID: String? = nil
    @Published var biometricType: LABiometryType = .none
    
    init() {
        checkBiometricAvailability()
        loadSavedCredentials()
    }
    
    // Check what biometric authentication is available
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
            print("🔒 Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    // Authenticate with Face ID/Touch ID
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // FIXED: Additional validation before attempting authentication
        guard savedBarID != nil else {
            completion(false, "No saved credentials found")
            return
        }
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, "Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        let reason = "Authenticate to access your bar controls"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    completion(true, nil)
                } else {
                    // FIXED: More specific error handling
                    let errorMessage: String
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel, .appCancel:
                            errorMessage = "Authentication was cancelled"
                        case .userFallback:
                            errorMessage = "User chose to enter password"
                        case .biometryNotAvailable:
                            errorMessage = "Biometric authentication is not available"
                        case .biometryNotEnrolled:
                            errorMessage = "Biometric authentication is not set up"
                        case .biometryLockout:
                            errorMessage = "Too many failed attempts. Please try again later"
                        default:
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error?.localizedDescription ?? "Authentication failed"
                    }
                    
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // Save credentials to Keychain after successful login
    func saveCredentials(barID: String, barName: String) {
        // FIXED: Validate inputs before saving
        guard !barID.isEmpty, !barName.isEmpty else {
            print("❌ Cannot save empty credentials")
            return
        }
        
        let service = "BarStatusTracker"
        let account = "SavedBarOwner"
        
        let credentials = "\(barID)|\(barName)"
        guard let data = credentials.data(using: .utf8) else {
            print("❌ Failed to encode credentials")
            return
        }
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status == errSecSuccess {
            savedBarID = barID
            print("✅ Successfully saved biometric credentials for bar: \(barName)")
        } else {
            print("❌ Failed to save credentials with status: \(status)")
        }
    }
    
    // Load saved credentials from Keychain
    func loadSavedCredentials() {
        let service = "BarStatusTracker"
        let account = "SavedBarOwner"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let credentials = String(data: data, encoding: .utf8) {
            let components = credentials.components(separatedBy: "|")
            if components.count == 2 {
                let barID = components[0]
                // FIXED: Validate the loaded credentials
                if !barID.isEmpty {
                    savedBarID = barID
                    print("✅ Loaded saved credentials for bar ID: \(barID)")
                } else {
                    print("❌ Invalid saved credentials - clearing")
                    clearCredentials()
                }
            } else {
                print("❌ Corrupted saved credentials - clearing")
                clearCredentials()
            }
        } else if status == errSecItemNotFound {
            print("ℹ️ No saved credentials found")
            savedBarID = nil
        } else {
            print("❌ Error loading credentials with status: \(status)")
            savedBarID = nil
        }
    }
    
    // Clear saved credentials (logout)
    func clearCredentials() {
        let service = "BarStatusTracker"
        let account = "SavedBarOwner"
        
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(deleteQuery as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Successfully cleared biometric credentials")
        } else {
            print("❌ Error clearing credentials with status: \(status)")
        }
        
        savedBarID = nil
        isAuthenticated = false
    }
    
    // FIXED: Validate that saved credentials are still valid
    func validateSavedCredentials() -> Bool {
        guard let savedBarID = savedBarID, !savedBarID.isEmpty else {
            return false
        }
        
        // Additional validation could be added here if needed
        // For now, just check that we have a non-empty ID
        return true
    }
    
    // Get biometric icon name for UI
    var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "person.badge.key"
        }
    }
    
    // Get biometric display name
    var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric"
        }
    }
    
    // FIXED: More robust check for biometric availability
    var isAvailable: Bool {
        return biometricType != .none && savedBarID != nil && validateSavedCredentials()
    }
}
