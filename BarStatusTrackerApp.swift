import SwiftUI
import FirebaseCore

@main
struct BarStatusTrackerApp: App {
    // Configure Firebase when app starts
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
