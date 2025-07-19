import SwiftUI

struct SearchBarsView: View {
    @ObservedObject var barViewModel: BarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search bars", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Results
                List(filteredBars) { bar in
                    // Fix: Use Button instead of onTapGesture to ensure full-width tapping
                    Button(action: {
                        barViewModel.selectedBar = bar
                        barViewModel.showingDetail = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(bar.name)
                                    .font(.headline)
                                    .foregroundColor(.primary) // Ensure text color is correct
                                Text(bar.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer() // This pushes content to left and makes tap area full width
                        }
                        .contentShape(Rectangle()) // Makes entire row tappable
                    }
                    .buttonStyle(PlainButtonStyle()) // Removes button styling
                }
            }
            .navigationTitle("Search Bars")
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
    
    private var filteredBars: [Bar] {
        let allBars = barViewModel.getAllBars()
        if searchText.isEmpty {
            return allBars
        }
        return allBars.filter { bar in
            bar.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}
