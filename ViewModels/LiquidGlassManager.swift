//
//  LiquidGlassManager.swift
//  BarStatusTracker
//
//  Created by Shuhei Kinugasa on 2025/09/07.
//

import SwiftUI

// MARK: - Liquid Glass Design System Manager
class LiquidGlassManager: ObservableObject {
    static let shared = LiquidGlassManager()
    
    private init() {}
    
    // MARK: - Liquid Glass Materials
    enum GlassLevel {
        case ultra    // .ultraThinMaterial - lightest, most transparent
        case thin     // .thinMaterial - medium transparency
        case regular  // .regularMaterial - more opaque
        case thick    // .thickMaterial - most opaque
        
        var material: Material {
            switch self {
            case .ultra: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            }
        }
    }
    
    // MARK: - Liquid Glass Corner Radius System
    enum CornerRadius {
        case small      // 8pt - small elements
        case medium     // 12pt - buttons, cards
        case large      // 16pt - larger cards, sections
        case extraLarge // 20pt - main containers
        case system     // 24pt - full screen elements
        
        var value: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            case .extraLarge: return 20
            case .system: return 24
            }
        }
    }
    
    // MARK: - Liquid Glass Shadow System
    enum ShadowLevel {
        case none
        case subtle
        case medium
        case prominent
        
        var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .none: return (.clear, 0, 0, 0)
            case .subtle: return (.black.opacity(0.05), 2, 0, 1)
            case .medium: return (.black.opacity(0.1), 4, 0, 2)
            case .prominent: return (.black.opacity(0.15), 8, 0, 4)
            }
        }
    }
}

// MARK: - Liquid Glass Container View
struct LiquidGlassContainer<Content: View>: View {
    let content: Content
    let glassLevel: LiquidGlassManager.GlassLevel
    let cornerRadius: LiquidGlassManager.CornerRadius
    let shadowLevel: LiquidGlassManager.ShadowLevel
    let borderOpacity: Double
    
    init(
        glassLevel: LiquidGlassManager.GlassLevel = .regular,
        cornerRadius: LiquidGlassManager.CornerRadius = .large,
        shadowLevel: LiquidGlassManager.ShadowLevel = .medium,
        borderOpacity: Double = 0.1,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.glassLevel = glassLevel
        self.cornerRadius = cornerRadius
        self.shadowLevel = shadowLevel
        self.borderOpacity = borderOpacity
    }
    
    var body: some View {
        content
            .background(liquidGlassBackground)
    }
    
    private var liquidGlassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius.value)
            .fill(glassLevel.material)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius.value)
                    .stroke(.primary.opacity(borderOpacity), lineWidth: 0.5)
            )
            .shadow(
                color: shadowLevel.shadow.color,
                radius: shadowLevel.shadow.radius,
                x: shadowLevel.shadow.x,
                y: shadowLevel.shadow.y
            )
    }
}

// MARK: - Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    let glassLevel: LiquidGlassManager.GlassLevel
    let cornerRadius: LiquidGlassManager.CornerRadius
    let isProminent: Bool
    
    init(
        glassLevel: LiquidGlassManager.GlassLevel = .thin,
        cornerRadius: LiquidGlassManager.CornerRadius = .medium,
        isProminent: Bool = false
    ) {
        self.glassLevel = glassLevel
        self.cornerRadius = cornerRadius
        self.isProminent = isProminent
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func buttonBackground(isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius.value)
            .fill(glassLevel.material)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius.value)
                    .stroke(.primary.opacity(isPressed ? 0.2 : 0.1), lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(isPressed ? 0.05 : 0.1),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
    }
}

// MARK: - Liquid Glass Text Field Style
struct LiquidGlassTextFieldStyle: TextFieldStyle {
    let glassLevel: LiquidGlassManager.GlassLevel
    let cornerRadius: LiquidGlassManager.CornerRadius
    
    init(
        glassLevel: LiquidGlassManager.GlassLevel = .thin,
        cornerRadius: LiquidGlassManager.CornerRadius = .medium
    ) {
        self.glassLevel = glassLevel
        self.cornerRadius = cornerRadius
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.value)
                    .fill(glassLevel.material)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius.value)
                            .stroke(.primary.opacity(0.15), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Liquid Glass Navigation Style
struct LiquidGlassNavigationStyle {
    static func apply() {
        // Tab Bar with Liquid Glass
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation Bar with Liquid Glass
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        navBarAppearance.shadowColor = UIColor.clear
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
}

// MARK: - View Extensions for Liquid Glass
extension View {
    func liquidGlass(
        level: LiquidGlassManager.GlassLevel = .regular,
        cornerRadius: LiquidGlassManager.CornerRadius = .large,
        shadow: LiquidGlassManager.ShadowLevel = .medium,
        borderOpacity: Double = 0.1
    ) -> some View {
        LiquidGlassContainer(
            glassLevel: level,
            cornerRadius: cornerRadius,
            shadowLevel: shadow,
            borderOpacity: borderOpacity
        ) {
            self
        }
    }
    
    func liquidGlassBackground() -> some View {
        self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 0))
    }
    
    // Apply the glass effect from iOS 18
    @available(iOS 16.0, *)
    func glassEffect(in shape: some Shape = RoundedRectangle(cornerRadius: 12)) -> some View {
        self.background(shape.fill(.thinMaterial))
    }
}

// MARK: - Liquid Glass Card Components
struct LiquidGlassCard<Content: View>: View {
    let content: Content
    let isInteractive: Bool
    let prominence: LiquidGlassManager.GlassLevel
    
    init(
        isInteractive: Bool = false,
        prominence: LiquidGlassManager.GlassLevel = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isInteractive = isInteractive
        self.prominence = prominence
    }
    
    var body: some View {
        content
            .padding()
            .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(prominence.material)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Liquid Glass Status Indicator
struct LiquidGlassStatusIndicator: View {
    let status: BarStatus
    let size: CGFloat
    
    init(status: BarStatus, size: CGFloat = 60) {
        self.status = status
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(status.color.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: status.color.opacity(0.2), radius: 8, x: 0, y: 4)
            
            Image(systemName: status.icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(status.color)
        }
    }
}

// MARK: - Liquid Glass Section Header
struct LiquidGlassSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(_ title: String, action: (() -> Void)? = nil, actionTitle: String? = nil) {
        self.title = title
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
