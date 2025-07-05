import SwiftUI
import FirebaseCore

@main
struct BarStatusTrackerApp: App {
    
    // Configure Firebase when app starts
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
