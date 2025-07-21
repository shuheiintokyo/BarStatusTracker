import SwiftUI

// MARK: - Simple Test Background
struct SimpleTestBackground<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Simple colored background that definitely works
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.mint.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            content
        }
    }
}

// MARK: - Image Test Component
struct ImageTestCard: View {
    let imageName: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Testing: \(imageName)")
                .font(.headline)
                .foregroundColor(.white)
            
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 120)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        Text("✅ FOUND")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4),
                        alignment: .topLeading
                    )
            } else {
                Rectangle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 200, height: 120)
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
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}

// MARK: - Main Background Test View
struct BackgroundTestView: View {
    let testImages = [
        "backgroundimg01",
        "backgroundimg02",
        "backgroundimg03",
        "backgroundimg04",
        "backgroundimg05"
    ]
    
    var body: some View {
        TabView {
            // Tab 1: Gradient Test
            SimpleTestBackground {
                VStack(spacing: 20) {
                    Text("Gradient Background Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    
                    Text("If you see blue/purple gradient, the structure works!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .shadow(radius: 1)
                    
                    Text("✅ Background system is working")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                .padding()
            }
            .tabItem {
                Label("Gradient", systemImage: "paintbrush")
            }
            
            // Tab 2: Image Asset Test
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Image Asset Test")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                        
                        ForEach(testImages, id: \.self) { imageName in
                            ImageTestCard(imageName: imageName)
                        }
                        
                        // Summary
                        let foundImages = testImages.filter { UIImage(named: $0) != nil }
                        
                        VStack(spacing: 10) {
                            Text("Summary")
                                .font(.headline)
                            
                            Text("Found: \(foundImages.count)/\(testImages.count) images")
                                .font(.subheadline)
                                .foregroundColor(foundImages.count == testImages.count ? .green : .orange)
                            
                            if foundImages.count > 0 {
                                Text("✅ Images are working!")
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            } else {
                                Text("❌ No images found")
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding()
                    }
                }
                .navigationTitle("Asset Debug")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Images", systemImage: "photo")
            }
            
            // Tab 3: Live Background Test
            ZStack {
                // Test actual background image
                if let firstFoundImage = testImages.first(where: { UIImage(named: $0) != nil }) {
                    Image(firstFoundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .opacity(0.7)
                        .blur(radius: 1.0)
                } else {
                    // Fallback
                    Color.red.opacity(0.3)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 20) {
                    Text("Live Background Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    
                    if testImages.contains(where: { UIImage(named: $0) != nil }) {
                        Text("✅ Background images working!")
                            .font(.title2)
                            .foregroundColor(.green)
                            .shadow(radius: 2)
                    } else {
                        Text("❌ Using fallback background")
                            .font(.title2)
                            .foregroundColor(.red)
                            .shadow(radius: 2)
                    }
                    
                    Text("This shows how your app will look")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(radius: 1)
                }
                .padding()
            }
            .tabItem {
                Label("Live Test", systemImage: "eye")
            }
        }
    }
}

#Preview {
    BackgroundTestView()
}
