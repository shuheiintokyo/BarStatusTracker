import SwiftUI

struct BarDetailView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var editingDescription = ""
    @State private var showingEditDescription = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(bar.name)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    
                                    Text(bar.address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: bar.status.icon)
                                        .font(.system(size: 40))
                                        .foregroundColor(bar.status.color)
                                    
                                    Text(bar.status.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            // Auto-transition info (if active)
                            if bar.isAutoTransitionActive, let pendingStatus = bar.pendingStatus {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.orange)
                                    
                                    Text("Will automatically change to \(pendingStatus.displayName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let timeRemaining = barViewModel.getTimeRemainingText(for: bar) {
                                        Text("in \(timeRemaining)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            if isOwnerMode {
                                StatusControlView(bar: bar, barViewModel: barViewModel)
                            }
                        }
                        
                        Divider()
                        
                        // Description
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("About")
                                    .font(.headline)
                                
                                if isOwnerMode {
                                    Spacer()
                                    Button("Edit") {
                                        editingDescription = bar.description
                                        showingEditDescription = true
                                    }
                                    .font(.caption)
                                }
                            }
                            
                            Text(bar.description.isEmpty ? "No description available." : bar.description)
                                .font(.body)
                                .foregroundColor(bar.description.isEmpty ? .secondary : .primary)
                        }
                        
                        // Social Links
                        if !bar.socialLinks.instagram.isEmpty || !bar.socialLinks.twitter.isEmpty || !bar.socialLinks.website.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Follow Us")
                                    .font(.headline)
                                
                                SocialLinksView(socialLinks: bar.socialLinks)
                            }
                        }
                        
                        // Analytics for bar owners
                        if isOwnerMode {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Analytics")
                                    .font(.headline)
                                
                                BarAnalyticsView(
                                    bar: bar,
                                    userPreferencesManager: barViewModel.userPreferencesManager
                                )
                            }
                        }
                        
                        Spacer(minLength: 100) // Space for floating button
                    }
                    .padding()
                }
                
                // Floating favorite button (for non-owners)
                if !isOwnerMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingFavoriteButton(
                                barId: bar.id,
                                userPreferencesManager: barViewModel.userPreferencesManager
                            )
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditDescription) {
            EditDescriptionView(description: $editingDescription) { newDescription in
                barViewModel.updateBarDescription(bar, newDescription: newDescription)
            }
        }
    }
}
