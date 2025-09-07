import SwiftUI
import FirebaseCore

// MARK: - App Delegate for Firebase and Liquid Glass Setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully via App Delegate")
        
        // Apply Liquid Glass Navigation Styling globally
        LiquidGlassNavigationStyle.apply()
        print("✨ Liquid Glass navigation styling applied globally")
        
        // Additional UI configurations for liquid glass system
        setupLiquidGlassAppearance()
        
        return true
    }
    
    private func setupLiquidGlassAppearance() {
        // Configure UIKit components to work better with liquid glass
        
        // Alert styling
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).backgroundColor = UIColor.clear
        
        // ActionSheet styling
        UIView.appearance(whenContainedInInstancesOf: [UIActivityViewController.self]).backgroundColor = UIColor.clear
        
        // Keyboard appearance
        UITextField.appearance().keyboardAppearance = .default
        UITextView.appearance().keyboardAppearance = .default
        
        // Status bar styling
        UIApplication.shared.statusBarStyle = .default
        
        print("🎨 Liquid Glass appearance configurations applied")
    }
}

// MARK: - SwiftUI App with Liquid Glass System
@main
struct BarStatusTrackerApp: App {
    // Register app delegate for Firebase and liquid glass setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Liquid glass manager for global state
    @StateObject private var liquidGlassManager = LiquidGlassManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Ensure liquid glass styling is applied on app launch
                    LiquidGlassNavigationStyle.apply()
                    
                    // Debug print to confirm system is loaded
                    print("🚀 Bar Status Tracker launched with Liquid Glass system")
                    #if DEBUG
                    BackgroundImageManager.shared.debugPrintAssignments()
                    #endif
                }
                .preferredColorScheme(.none) // Allow system to determine color scheme
        }
    }
}

// MARK: - Updated ContentView for Liquid Glass
struct ContentView: View {
    var body: some View {
        MainContentView()
            .background(.regularMaterial) // Apply base liquid glass material
            .onAppear {
                // Additional setup if needed
                print("📱 Main content view loaded with liquid glass background")
            }
    }
}
