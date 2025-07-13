import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct BarStatusTrackerApp: App {
    @StateObject private var notificationManager = NotificationManager()
    
    // Configure Firebase when app starts
    init() {
        FirebaseApp.configure()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
        }
    }
}
