import SwiftUI

// MARK: - Background Image Manager
class BackgroundImageManager: ObservableObject {
    static let shared = BackgroundImageManager()
    
    private let backgroundImages = [
        "backgroundimg01",
        "backgroundimg02",
        "backgroundimg03",
        "backgroundimg04",
        "backgroundimg05"
    ]
    
    // Cache for consistent images per view type
    private var viewImageCache: [String: String] = [:]
    
    func getBackgroundImage(for viewIdentifier: String) -> String {
        // If we already assigned an image to this view type, use it
        if let cachedImage = viewImageCache[viewIdentifier] {
            return cachedImage
        }
        
        // Otherwise, randomly select one and cache it
        let randomImage = backgroundImages.randomElement() ?? "backgroundimg01"
        viewImageCache[viewIdentifier] = randomImage
        return randomImage
    }
    
    func getRandomBackgroundImage() -> String {
        return backgroundImages.randomElement() ?? "backgroundimg01"
    }
    
    // Reset cache to get new random images
    func refreshBackgrounds() {
        viewImageCache.removeAll()
    }
}

// MARK: - Stylish Background View Component
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
            // Background Image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: blurRadius)
                .opacity(opacity)
            
            // Dark overlay for better text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.2)
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
