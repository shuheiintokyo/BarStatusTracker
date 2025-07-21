import SwiftUI
import FirebaseCore

// MARK: - App Delegate for Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully via App Delegate")
        return true
    }
}

// MARK: - SwiftUI App with Proper App Delegate
@main
struct BarStatusTrackerApp: App {
    // Register app delegate for Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
