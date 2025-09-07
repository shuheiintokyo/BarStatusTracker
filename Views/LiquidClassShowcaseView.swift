import SwiftUI

// MARK: - Comprehensive Liquid Glass Showcase View
struct LiquidGlassShowcaseView: View {
    @State private var textInput = ""
    @State private var sliderValue: Double = 0.5
    @State private var toggleValue = true
    @State private var selectedSegment = 0
    @State private var showingSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section with multiple glass levels
                    heroSection
                    
                    // Status indicators showcase
                    statusIndicatorsSection
                    
                    // Interactive components
                    interactiveComponentsSection
                    
                    // Form elements
                    formElementsSection
                    
                    // Button styles
                    buttonStylesSection
                    
                    // Cards and containers
                    cardsSection
                    
                    // Navigation and sheets
                    navigationSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(.regularMaterial)
            .navigationTitle("Liquid Glass Showcase")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetShowcase()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            LiquidGlassSheetDemo()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Title with ultra-thin glass
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Liquid Glass System")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Premium UI components with glass morphism")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .liquidGlass(level: .ultra, cornerRadius: .extraLarge, shadow: .prominent)
            
            // Glass level demonstration
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                GlassLevelDemo(level: .ultra, title: "Ultra Thin", icon: "circle")
                GlassLevelDemo(level: .thin, title: "Thin", icon: "circle.fill")
                GlassLevelDemo(level: .regular, title: "Regular", icon: "circle.circle")
                GlassLevelDemo(level: .thick, title: "Thick", icon: "circle.circle.fill")
            }
        }
    }
    
    // MARK: - Status Indicators Section
    private var statusIndicatorsSection: some View {
        VStack(spacing: 16) {
            LiquidGlassSectionHeader("Status Indicators")
            
            VStack(spacing: 12) {
                Text("Bar Status Examples")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        LiquidGlassStatusIndicator(status: .open, size: 60)
                        Text("Open")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 8) {
                        LiquidGlassStatusIndicator(status: .openingSoon, size: 60)
                        Text("Opening Soon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 8) {
                        LiquidGlassStatusIndicator(status: .closingSoon, size: 60)
                        Text("Closing Soon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 8) {
                        LiquidGlassStatusIndicator(status: .closed, size: 60)
                        Text("Closed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Interactive Components Section
    private var interactiveComponentsSection: some View {
        VStack(spacing: 16) {
            LiquidGlassSectionHeader("Interactive Components")
            
            VStack(spacing: 20) {
                // Toggle
                HStack {
                    Text("Liquid Glass Toggle")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Toggle("", isOn: $toggleValue)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Divider()
                    .background(.primary.opacity(0.1))
                
                // Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Liquid Glass Slider")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(Int(sliderValue * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $sliderValue, in: 0...1)
                        .tint(.blue)
                }
                
                Divider()
                    .background(.primary.opacity(0.1))
                
                // Segmented Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Liquid Glass Picker")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Picker("Options", selection: $selectedSegment) {
                        Text("First").tag(0)
                        Text("Second").tag(1)
                        Text("Third").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Form Elements Section
    private var formElementsSection: some View {
        VStack(spacing: 16) {
            LiquidGlassSectionHeader("Form Elements")
            
            VStack(spacing: 16) {
                // Text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Liquid Glass Text Field")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    TextField("Enter some text here...", text: $textInput)
                        .textFieldStyle(LiquidGlassTextFieldStyle())
                }
                
                // Secure field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Liquid Glass Secure Field")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    SecureField("Enter password...", text: .constant(""))
                        .textFieldStyle(LiquidGlassTextFieldStyle())
                }
                
                // Text with validation
                if !textInput.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Input validated successfully")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding()
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Button Styles Section
    private var buttonStylesSection: some View {
        VStack(spacing: 16) {
            LiquidGlassSectionHeader("Button Styles")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                Button("Ultra Thin") { }
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .ultra, cornerRadius: .medium))
                    .foregroundColor(.blue)
                
                Button("Thin Glass") { }
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
                    .foregroundColor(.green)
                
                Button("Regular Glass") { }
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .regular, cornerRadius: .medium))
                    .foregroundColor(.orange)
                
                Button("Thick Glass") { }
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thick, cornerRadius: .medium))
                    .foregroundColor(.purple)
            }
            
            // Action buttons with different styles
            VStack(spacing: 8) {
                Button("Primary Action") { }
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .large, isProminent: true))
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                
                Button("Secondary Action") { }
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .regular, cornerRadius: .medium))
                    .foregroundColor(.primary)
                
                Button("Destructive Action") { }
                    .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
                    .foregroundColor(.red)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Cards Section
    private var cardsSection: some View {
        VStack(spacing: 16) {
            LiquidGlassSectionHeader("Cards & Containers")
            
            // Basic card
            LiquidGlassCard(isInteractive: false, prominence: .regular) {
                VStack(spacing: 8) {
                    Text("Basic Card")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("This is a non-interactive card with regular glass level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Interactive card
            LiquidGlassCard(isInteractive: true, prominence: .thin) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "hand.tap")
                            .foregroundColor(.blue)
                        Text("Interactive Card")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("This card responds to touch interactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Nested glass effect
            VStack(spacing: 12) {
                Text("Nested Glass Effects")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    VStack {
                        Text("Level 1")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .liquidGlass(level: .ultra, cornerRadius: .medium, shadow: .subtle)
                    
                    VStack {
                        Text("Level 2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .liquidGlass(level: .thin, cornerRadius: .medium, shadow: .subtle)
                    
                    VStack {
                        Text("Level 3")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .liquidGlass(level: .regular, cornerRadius: .medium, shadow: .subtle)
                }
            }
            .liquidGlass(level: .thick, cornerRadius: .large, shadow: .medium)
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Navigation Section
    private var navigationSection: some View {
        VStack(spacing: 16) {
            LiquidGlassSectionHeader("Navigation & Sheets")
            
            VStack(spacing: 12) {
                Button("Show Liquid Glass Sheet") {
                    showingSheet = true
                }
                .buttonStyle(LiquidGlassButtonStyle(glassLevel: .thin, cornerRadius: .medium))
                .foregroundColor(.blue)
                
                Text("Demonstrates sheet presentation with liquid glass styling")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Helper Functions
    private func resetShowcase() {
        textInput = ""
        sliderValue = 0.5
        toggleValue = true
        selectedSegment = 0
    }
}

// MARK: - Glass Level Demo Component
struct GlassLevelDemo: View {
    let level: LiquidGlassManager.GlassLevel
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text("Material")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .liquidGlass(level: level, cornerRadius: .medium, shadow: .subtle)
    }
}

// MARK: - Sheet Demo
struct LiquidGlassSheetDemo: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Liquid Glass Sheet")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("This sheet demonstrates liquid glass styling in modal presentation")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .liquidGlass(level: .ultra, cornerRadius: .large, shadow: .subtle)
                    
                    // Content sections
                    ForEach(0..<3) { index in
                        VStack(spacing: 8) {
                            Text("Section \(index + 1)")
                                .font(.headline)
                            
                            Text("This is content section \(index + 1) with liquid glass styling")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .liquidGlass(level: .regular, cornerRadius: .medium, shadow: .medium)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(.regularMaterial)
            .navigationTitle("Demo Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    LiquidGlassShowcaseView()
}//
//  LiquidClassShowcaseView.swift
//  BarStatusTracker
//
//  Created by Shuhei Kinugasa on 2025/09/07.
//

