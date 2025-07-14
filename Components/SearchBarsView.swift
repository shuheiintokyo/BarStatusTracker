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
                    VStack(alignment: .leading) {
                        Text(bar.name)
                            .font(.headline)
                        Text(bar.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        barViewModel.selectedBar = bar
                        barViewModel.showingDetail = true
                    }
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
