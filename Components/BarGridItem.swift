import SwiftUI

struct BarGridItem: View {
    let bar: Bar
    let isOwnerMode: Bool
    @ObservedObject var barViewModel: BarViewModel
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = false
                }
                onTap()
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                // Card background - matches screenshot
                RoundedRectangle(cornerRadius: 16)
                    .fill(bar.status.color)
                    .frame(height: 140)
                
                VStack(spacing: 0) {
                    // Top section with heart icon (exactly like screenshot)
                    HStack {
                        Spacer()
                        
                        // Red heart icon in top-right corner (like in screenshot)
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    
                    Spacer()
                    
                    // Center content - Status icon (white circle with checkmark like screenshot)
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: bar.status.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Bottom section - Bar name and status (exactly like screenshot)
                    VStack(spacing: 4) {
                        Text(bar.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        
                        Text(bar.status.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        
                        // Small number at bottom (like "3" in screenshot)
                        Text("3")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 2)
                    }
                    .padding(.bottom, 16)
                }
            }
            .scaleEffect({
                let scale = isPressed ? 0.95 : 1.0
                return scale.isFinite ? max(0.5, min(2.0, scale)) : 1.0
            }())
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
