import SwiftUI

class BarViewModel: ObservableObject {
    @Published var bars: [Bar] = []
    @Published var isLoading = false
    @Published var selectedBar: Bar?
    @Published var showingDetail = false
    
    init() {
        loadSampleData()
    }
    
    func loadSampleData() {
        bars = [
            Bar(name: "The Cozy Corner", latitude: 37.7749, longitude: -122.4194, address: "123 Main St", status: .open, description: "A warm, welcoming neighborhood bar with craft cocktails and local beer."),
            Bar(name: "Sunset Tavern", latitude: 37.7849, longitude: -122.4094, address: "456 Oak Ave", status: .closingSoon, description: "Perfect spot to watch the sunset with friends."),
            Bar(name: "The Underground", latitude: 37.7649, longitude: -122.4294, address: "789 Pine St", status: .closed, description: "Speakeasy-style bar with vintage cocktails."),
            Bar(name: "Harbor Lights", latitude: 37.7549, longitude: -122.4394, address: "321 Beach Blvd", status: .openingSoon, description: "Waterfront bar with live music every weekend."),
            Bar(name: "City View Lounge", latitude: 37.7949, longitude: -122.3994, address: "654 Hill St", status: .open, description: "Rooftop bar with panoramic city views."),
            Bar(name: "The Local Pub", latitude: 37.7449, longitude: -122.4494, address: "987 First St", status: .closed, description: "Traditional pub with hearty food and cold beer.")
        ]
    }
    
    func updateBarStatus(_ bar: Bar, newStatus: BarStatus) {
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].status = newStatus
            bars[index].lastUpdated = Date()
        }
    }
    
    func updateBarDescription(_ bar: Bar, newDescription: String) {
        if let index = bars.firstIndex(where: { $0.id == bar.id }) {
            bars[index].description = newDescription
            bars[index].lastUpdated = Date()
        }
    }
}
