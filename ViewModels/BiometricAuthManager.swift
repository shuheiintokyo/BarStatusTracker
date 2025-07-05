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
        }
    }
    
    // Authenticate with Face ID/Touch ID
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, "Biometric authentication not available")
            return
        }
        
        let reason = "Authenticate to access your bar controls"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    self.loadSavedCredentials()
                    completion(true, nil)
                } else {
                    completion(false, error?.localizedDescription ?? "Authentication failed")
                }
            }
        }
    }
    
    // Save credentials to Keychain after successful login
    func saveCredentials(barID: String, barName: String) {
        let service = "BarStatusTracker"
        let account = "SavedBarOwner"
        
        let credentials = "\(barID)|\(barName)"
        let data = credentials.data(using: .utf8)!
        
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
        
        SecItemAdd(addQuery as CFDictionary, nil)
        savedBarID = barID
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
                savedBarID = components[0]
            }
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
        SecItemDelete(deleteQuery as CFDictionary)
        
        savedBarID = nil
        isAuthenticated = false
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
}
