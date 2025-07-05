import SwiftUI

class BarViewModel: ObservableObject {
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var selectedBar: Bar?
    @Published var showingDetail = false
    
    // New authentication properties
    @Published var loggedInBar: Bar? = nil
    @Published var isOwnerMode = false
    
    init() {
        loadSampleData()
    }
    
    func loadSampleData() {
        bars = [
            Bar(name: "The Cozy Corner", latitude: 37.7749, longitude: -122.4194, address: "123 Main St", status: .open, description: "A warm, welcoming neighborhood bar with craft cocktails and local beer.", password: "1234"),
            Bar(name: "Sunset Tavern", latitude: 37.7849, longitude: -122.4094, address: "456 Oak Ave", status: .closingSoon, description: "Perfect spot to watch the sunset with friends.", password: "5678"),
            Bar(name: "The Underground", latitude: 37.7649, longitude: -122.4294, address: "789 Pine St", status: .closed, description: "Speakeasy-style bar with vintage cocktails.", password: "9012"),
            Bar(name: "Harbor Lights", latitude: 37.7549, longitude: -122.4394, address: "321 Beach Blvd", status: .openingSoon, description: "Waterfront bar with live music every weekend.", password: "3456"),
            Bar(name: "City View Lounge", latitude: 37.7949, longitude: -122.3994, address: "654 Hill St", status: .open, description: "Rooftop bar with panoramic city views.", password: "7890"),
            Bar(name: "The Local Pub", latitude: 37.7449, longitude: -122.4494, address: "987 First St", status: .closed, description: "Traditional pub with hearty food and cold beer.", password: "2468")
        ]
    }
    
    // Authentication function
    func authenticateBar(username: String, password: String) -> Bool {
        if let bar = bars.first(where: { $0.username.lowercased() == username.lowercased() && $0.password == password }) {
            loggedInBar = bar
            isOwnerMode = true
            return true
        }
        return false
    }
    
    // Logout function
    func logout() {
        loggedInBar = nil
        isOwnerMode = false
    }
    
    // Check if current user can edit this bar
    func canEdit(bar: Bar) -> Bool {
        guard let loggedInBar = loggedInBar else { return false }
        return loggedInBar.id == bar.id
    }
    
    // Update bar status (only if owner)
    func updateBarStatus(_ bar: Bar, newStatus: BarStatus) {
        guard canEdit(bar: bar) else { return }
        
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].status = newStatus
            bars[index].lastUpdated = Date()
            
            // Update logged in bar reference
            if loggedInBar?.id == bar.id {
                loggedInBar = bars[index]
            }
        }
    }
    
    // Update bar description (only if owner)
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        guard canEdit(bar: bar) else { return }
        
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].description = newDescription
            bars[index].lastUpdated = Date()
            
            // Update logged in bar reference
            if loggedInBar?.id == bar.id {
                loggedInBar = bars[index]
            }
        }
    }
    
    // Get all bars for general users
    func getAllBars() -> [Bar] {
        return bars
    }
    
    // Get only the logged-in bar for owners
    func getOwnerBars() -> [Bar] {
        guard let loggedInBar = loggedInBar else { return [] }
        return [loggedInBar]
    }
}
