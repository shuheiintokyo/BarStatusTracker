import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if notificationManager.isAuthorized {
                    // ✅ Notifications enabled - show settings
                    notificationSettingsView
                } else {
                    // ❌ No permission - show permission request
                    permissionRequestView
                }
            }
            .padding()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Permission Request View
    var permissionRequestView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("🍺 Bar Status Notifications")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get notified when bars are about to open or close!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                NotificationFeatureRow(
                    icon: "clock.badge.checkmark",
                    title: "Opening Soon",
                    description: "Know when bars are about to open"
                )
                
                NotificationFeatureRow(
                    icon: "clock.badge.exclamationmark",
                    title: "Closing Soon",
                    description: "Last call notifications"
                )
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Button(action: {
                notificationManager.requestNotificationPermissions()
            }) {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("Enable Notifications")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            Button("Open Settings") {
                notificationManager.openNotificationSettings()
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    // MARK: - Simplified Notification Settings View
    var notificationSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔔 Notifications Enabled")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Get alerts for all bars opening and closing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Global notification toggle
                VStack(alignment: .leading, spacing: 16) {
                    Text("📱 Notification Control")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Enable All Notifications")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Receive notifications for all bar status changes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { notificationManager.enableNotifications },
                                set: { _ in notificationManager.toggleNotifications() }
                            ))
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Sound Settings Section (only if notifications are enabled)
                if notificationManager.enableNotifications {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🎵 Sound Settings")
                            .font(.headline)
                        
                        VStack(spacing: 16) {
                            // Opening Soon notifications
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Opening Soon Notifications")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("When bars are about to open")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { notificationManager.enableSoundsForOpen },
                                        set: { _ in notificationManager.toggleSoundForOpen() }
                                    ))
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.badge.checkmark")
                                        .foregroundColor(.mint)
                                    Text("Opening Soon")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.mint.opacity(0.05))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.mint.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Closing Soon notifications
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Closing Soon Notifications")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Last call alerts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { notificationManager.enableSoundsForClosing },
                                        set: { _ in notificationManager.toggleSoundForClosing() }
                                    ))
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                        .foregroundColor(.yellow)
                                    Text("Closing Soon")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.05))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Test Notification Button
                Button(action: {
                    testNotification()
                }) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                        Text("Test Notification Sound")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
                }
                
                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("ℹ️ About Notifications")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Receive notifications for all bars in the app")
                        Text("• Opening Soon: When bars are about to open")
                        Text("• Closing Soon: When bars are about to close")
                        Text("• Notifications are sent based on bar schedules and manual updates")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
                
                // Available Bars Section
                availableBarsList
                
                Spacer()
            }
        }
    }
    
    // MARK: - Test Notification
    private func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎵 Sound Test"
        content.body = "This is how your notifications will sound!"
        content.sound = .default
        
        let identifier = "sound-test-\(Date().timeIntervalSince1970)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to test sound: \(error)")
            } else {
                print("🎵 Testing notification sound")
            }
        }
    }
    
    // MARK: - Available Bars List (Simplified)
    var availableBarsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🍺 Available Bars")
                .font(.headline)
            
            let allBars = barViewModel.getAllBars()
            
            if allBars.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "building.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Bars Available")
                        .font(.headline)
                    
                    Text("When bars are available, you'll receive notifications about their opening and closing times")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create New Bar") {
                        dismiss()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(allBars.prefix(5)) { bar in
                        SimpleBarRow(bar: bar)
                    }
                    
                    if allBars.count > 5 {
                        Text("... and \(allBars.count - 5) more bars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                
                if notificationManager.enableNotifications {
                    Text("💡 You'll receive notifications when any of these bars are opening or closing soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                } else {
                    Text("🔕 Notifications are disabled - enable them above to get alerts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Helper Views

struct NotificationFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SimpleBarRow: View {
    let bar: Bar
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bar.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: bar.status.icon)
                        .foregroundColor(bar.status.color)
                    Text(bar.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let location = bar.location {
                        Text("• \(location.city)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.mint)
                        .font(.caption)
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Text("Notifications")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}
