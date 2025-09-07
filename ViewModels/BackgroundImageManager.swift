import SwiftUI

// MARK: - Enhanced Background Gradient Manager (Replacing Images)
class BackgroundImageManager: ObservableObject {
    static let shared = BackgroundImageManager()
    
    // Gradient configurations replacing background images
    private let backgroundGradients: [BackgroundGradient] = [
        BackgroundGradient(
            name: "background01",
            colors: [.blue.opacity(0.4), .purple.opacity(0.3), .indigo.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        BackgroundGradient(
            name: "background02",
            colors: [.green.opacity(0.3), .mint.opacity(0.4), .teal.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        BackgroundGradient(
            name: "background03",
            colors: [.orange.opacity(0.3), .pink.opacity(0.3), .red.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        BackgroundGradient(
            name: "background04",
            colors: [.purple.opacity(0.3), .pink.opacity(0.4), .blue.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        BackgroundGradient(
            name: "background05",
            colors: [.indigo.opacity(0.4), .blue.opacity(0.3), .cyan.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ]
    
    // Pre-assigned gradients for specific views for consistency
    private let viewGradientMap: [String: String] = [
        "main_app": "background01",
        "home_view": "background01",
        "discover_view": "background02",
        "account_view": "background03",
        "owner_login": "background04",
        "create_bar": "background05",
        "bar_detail": "background01",
        "search_bars": "background02",
        "location_browser": "background03",
        "welcome": "background04",
        "schedule_editor": "background05"
    ]
    
    // Cache for consistent random gradients per view type
    private var randomGradientCache: [String: String] = [:]
    
    func getBackgroundGradient(for viewIdentifier: String) -> BackgroundGradient {
        // First check if we have a pre-assigned gradient for this view
        if let assignedGradientName = viewGradientMap[viewIdentifier],
           let gradient = backgroundGradients.first(where: { $0.name == assignedGradientName }) {
            return gradient
        }
        
        // If we already assigned a random gradient to this view type, use it
        if let cachedGradientName = randomGradientCache[viewIdentifier],
           let gradient = backgroundGradients.first(where: { $0.name == cachedGradientName }) {
            return gradient
        }
        
        // Otherwise, randomly select one and cache it
        let randomGradient = backgroundGradients.randomElement() ?? backgroundGradients[0]
        randomGradientCache[viewIdentifier] = randomGradient.name
        return randomGradient
    }
    
    func getRandomBackgroundGradient() -> BackgroundGradient {
        return backgroundGradients.randomElement() ?? backgroundGradients[0]
    }
    
    // Get a specific gradient by index (useful for testing)
    func getBackgroundGradient(at index: Int) -> BackgroundGradient {
        guard index >= 0 && index < backgroundGradients.count else {
            return backgroundGradients[0]
        }
        return backgroundGradients[index]
    }
    
    // Get all available gradients
    func getAllBackgroundGradients() -> [BackgroundGradient] {
        return backgroundGradients
    }
    
    // Reset cache to get new random gradients
    func refreshBackgrounds() {
        randomGradientCache.removeAll()
    }
    
    // Debug: Print current assignments
    func debugPrintAssignments() {
        print("🎨 Background Gradient Assignments:")
        print("📍 Pre-assigned:")
        for (view, gradientName) in viewGradientMap.sorted(by: { $0.key < $1.key }) {
            print("   \(view): \(gradientName)")
        }
        print("🎲 Random cache:")
        for (view, gradientName) in randomGradientCache.sorted(by: { $0.key < $1.key }) {
            print("   \(view): \(gradientName)")
        }
    }
}

// MARK: - Background Gradient Model
struct BackgroundGradient {
    let name: String
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

// MARK: - Enhanced Stylish Background View Component (Using Gradients)
struct StylishBackgroundView<Content: View>: View {
    let gradient: BackgroundGradient
    let content: Content
    let additionalOpacity: Double
    
    init(
        gradient: BackgroundGradient,
        additionalOpacity: Double = 1.0,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.additionalOpacity = additionalOpacity
        self.content = content()
    }
    
    // Convenience initializer with gradient name
    init(
        gradientName: String,
        additionalOpacity: Double = 1.0,
        @ViewBuilder content: () -> Content
    ) {
        let manager = BackgroundImageManager.shared
        self.gradient = manager.getBackgroundGradient(for: gradientName)
        self.additionalOpacity = additionalOpacity
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            gradient.gradient
                .ignoresSafeArea()
                .opacity(additionalOpacity)
            
            // Additional dark overlay for better text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            content
        }
    }
}

// MARK: - View Extension for Easy Background Assignment
extension View {
    func withStylishBackground(_ viewIdentifier: String) -> some View {
        let manager = BackgroundImageManager.shared
        let gradient = manager.getBackgroundGradient(for: viewIdentifier)
        
        return StylishBackgroundView(gradient: gradient) {
            self
        }
    }
    
    func withCustomGradient(_ gradient: BackgroundGradient, opacity: Double = 1.0) -> some View {
        return StylishBackgroundView(
            gradient: gradient,
            additionalOpacity: opacity
        ) {
            self
        }
    }
    
    func withSimpleGradient(colors: [Color], startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> some View {
        let gradient = BackgroundGradient(
            name: "custom",
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        
        return StylishBackgroundView(gradient: gradient) {
            self
        }
    }
}
