import SwiftUI

// MARK: - Enhanced Background Image Manager
class BackgroundImageManager: ObservableObject {
    static let shared = BackgroundImageManager()
    
    private let backgroundImages = [
        "backgroundimg01",
        "backgroundimg02",
        "backgroundimg03",
        "backgroundimg04",
        "backgroundimg05"
    ]
    
    // Pre-assigned backgrounds for specific views for consistency
    private let viewBackgroundMap: [String: String] = [
        "main_app": "backgroundimg01",
        "home_view": "backgroundimg01",
        "discover_view": "backgroundimg02",
        "account_view": "backgroundimg03",
        "owner_login": "backgroundimg04",
        "create_bar": "backgroundimg05",
        "bar_detail": "backgroundimg01",
        "search_bars": "backgroundimg02",
        "location_browser": "backgroundimg03",
        "welcome": "backgroundimg04",
        "schedule_editor": "backgroundimg05"
    ]
    
    // Cache for consistent random images per view type
    private var randomImageCache: [String: String] = [:]
    
    func getBackgroundImage(for viewIdentifier: String) -> String {
        // First check if we have a pre-assigned background for this view
        if let assignedImage = viewBackgroundMap[viewIdentifier] {
            return assignedImage
        }
        
        // If we already assigned a random image to this view type, use it
        if let cachedImage = randomImageCache[viewIdentifier] {
            return cachedImage
        }
        
        // Otherwise, randomly select one and cache it
        let randomImage = backgroundImages.randomElement() ?? "backgroundimg01"
        randomImageCache[viewIdentifier] = randomImage
        return randomImage
    }
    
    func getRandomBackgroundImage() -> String {
        return backgroundImages.randomElement() ?? "backgroundimg01"
    }
    
    // Get a specific background image by index (useful for testing)
    func getBackgroundImage(at index: Int) -> String {
        guard index >= 0 && index < backgroundImages.count else {
            return "backgroundimg01"
        }
        return backgroundImages[index]
    }
    
    // Get all available background images
    func getAllBackgroundImages() -> [String] {
        return backgroundImages
    }
    
    // Reset cache to get new random images
    func refreshBackgrounds() {
        randomImageCache.removeAll()
    }
    
    // Debug: Print current assignments
    func debugPrintAssignments() {
        print("📸 Background Image Assignments:")
        print("📍 Pre-assigned:")
        for (view, image) in viewBackgroundMap.sorted(by: { $0.key < $1.key }) {
            print("   \(view): \(image)")
        }
        print("🎲 Random cache:")
        for (view, image) in randomImageCache.sorted(by: { $0.key < $1.key }) {
            print("   \(view): \(image)")
        }
    }
}

// MARK: - Enhanced Stylish Background View Component
struct StylishBackgroundView<Content: View>: View {
    let imageName: String
    let content: Content
    let opacity: Double
    let blurRadius: CGFloat
    
    init(
        imageName: String,
        opacity: Double = 0.3,
        blurRadius: CGFloat = 2.0,
        @ViewBuilder content: () -> Content
    ) {
        self.imageName = imageName
        self.opacity = opacity
        self.blurRadius = blurRadius
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Background Image with validation
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .blur(radius: blurRadius)
                    .opacity(opacity)
            } else {
                // Fallback gradient if image not found
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.2),
                        Color.indigo.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .opacity(opacity)
                
                // Debug overlay in development
                #if DEBUG
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("⚠️ Image '\(imageName)' not found")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                .padding()
                #endif
            }
            
            // Dark overlay for better text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.10)
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
        let imageName = manager.getBackgroundImage(for: viewIdentifier)
        
        return StylishBackgroundView(imageName: imageName) {
            self
        }
    }
    
    func withCustomBackground(_ imageName: String, opacity: Double = 0.3, blurRadius: CGFloat = 2.0) -> some View {
        return StylishBackgroundView(
            imageName: imageName,
            opacity: opacity,
            blurRadius: blurRadius
        ) {
            self
        }
    }
}

// MARK: - Background Testing View for Development
#if DEBUG
struct BackgroundTestView: View {
    @StateObject private var backgroundManager = BackgroundImageManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Background Image Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    // Test each background image
                    ForEach(Array(backgroundManager.getAllBackgroundImages().enumerated()), id: \.offset) { index, imageName in
                        VStack(spacing: 8) {
                            Text("Testing: \(imageName)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if UIImage(named: imageName) != nil {
                                Image(imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        HStack {
                                            Text("✅ FOUND")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                                .padding(4)
                                                .background(Color.white.opacity(0.8))
                                                .cornerRadius(4)
                                            Spacer()
                                        }
                                        .padding(8),
                                        alignment: .topLeading
                                    )
                            } else {
                                Rectangle()
                                    .fill(Color.red.opacity(0.6))
                                    .frame(height: 120)
                                    .cornerRadius(12)
                                    .overlay(
                                        VStack {
                                            Text("❌")
                                                .font(.largeTitle)
                                            Text("NOT FOUND")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                        )
                    }
                    
                    // Debug button
                    Button("Print Assignments") {
                        backgroundManager.debugPrintAssignments()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .withStylishBackground("background_test")
            .navigationTitle("Background Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
