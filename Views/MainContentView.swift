import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @State private var showingOwnerLogin = false
    @State private var isOwnerMode = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Bar Status Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        if isOwnerMode {
                            isOwnerMode = false
                        } else {
                            showingOwnerLogin = true
                        }
                    }) {
                        Image(systemName: isOwnerMode ? "person.fill.badge.minus" : "person.badge.key")
                            .font(.title2)
                    }
                }
                .padding()
                
                // Map Grid View
                BarGridView(barViewModel: barViewModel, isOwnerMode: isOwnerMode)
            }
        }
        .sheet(isPresented: $showingOwnerLogin) {
            OwnerLoginView(isOwnerMode: $isOwnerMode)
        }
        .sheet(isPresented: $barViewModel.showingDetail) {
            if let selectedBar = barViewModel.selectedBar {
                BarDetailView(bar: selectedBar, barViewModel: barViewModel, isOwnerMode: isOwnerMode)
            }
        }
    }
}
