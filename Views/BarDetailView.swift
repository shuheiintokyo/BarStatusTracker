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
                    
                    Spacer()
                }
                .padding()
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
