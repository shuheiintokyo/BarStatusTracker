import SwiftUI

struct MainContentView: View {
    @StateObject private var barViewModel = BarViewModel()
    @State private var showingOwnerLogin = false
    
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
                        if barViewModel.isOwnerMode {
                            barViewModel.logout()
                        } else {
                            showingOwnerLogin = true
                        }
                    }) {
                        HStack {
                            Image(systemName: barViewModel.isOwnerMode ? "person.fill.badge.minus" : "person.badge.key")
                                .font(.title2)
                            
                            if barViewModel.isOwnerMode, let loggedInBar = barViewModel.loggedInBar {
                                Text(loggedInBar.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                
                // Grid View
                BarGridView(barViewModel: barViewModel, isOwnerMode: barViewModel.isOwnerMode)
            }
        }
        .sheet(isPresented: $showingOwnerLogin) {
            OwnerLoginView(barViewModel: barViewModel, showingOwnerLogin: $showingOwnerLogin)
        }
        .sheet(isPresented: $barViewModel.showingDetail) {
            if let selectedBar = barViewModel.selectedBar {
                BarDetailView(bar: selectedBar, barViewModel: barViewModel, isOwnerMode: barViewModel.isOwnerMode)
            }
        }
    }
}
