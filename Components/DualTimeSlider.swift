import SwiftUI

// MARK: - Clean and Simple Dual Time Slider for Operating Hours with Liquid Glass
struct DualTimeSlider: View {
    @Binding var openTime: String
    @Binding var closeTime: String
    @State private var showingOpenTime = false
    @State private var showingCloseTime = false
    
    private var openPosition: Double {
        let position = timeToPosition(openTime)
        return position.isFinite ? position : 0.0
    }
    
    private var closePosition: Double {
        let position = timeToPosition(closeTime)
        return position.isFinite ? position : 0.0
    }
    
    private let timeSlots = [
        "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
        "21:00", "21:30", "22:00", "22:30", "23:00", "23:30",
        "00:00", "00:30", "01:00", "01:30", "02:00", "02:30",
        "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00"
    ]
    
    private let majorTimeMarkers = ["18:00", "21:00", "00:00", "03:00", "06:00"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Clean time display with liquid glass
            HStack {
                timeDisplayCard(time: openTime, label: "Opens", color: .green, isShowing: $showingOpenTime)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                    .font(.title3)
                
                Spacer()
                
                timeDisplayCard(time: closeTime, label: "Closes", color: .red, isShowing: $showingCloseTime)
            }
            
            // Simplified slider track with liquid glass background
            GeometryReader { geometry in
                let rawWidth = geometry.size.width
                let width = rawWidth > 0 && rawWidth.isFinite ? max(100.0, rawWidth) : 300.0
                let height: CGFloat = 44
                
                ZStack(alignment: .leading) {
                    // Background track with liquid glass
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(.ultraThinMaterial)
                        .frame(height: height)
                        .overlay(
                            RoundedRectangle(cornerRadius: height / 2)
                                .stroke(.primary.opacity(0.1), lineWidth: 0.5)
                        )
                    
                    // Active range with liquid glass gradient
                    let minPos = min(openPosition, closePosition)
                    let maxPos = max(openPosition, closePosition)
                    let startX = width * minPos
                    let endX = width * maxPos
                    let activeWidth = max(0, endX - startX)
                    
                    let safeStartX = startX.isFinite ? max(0, min(width, startX)) : 0
                    let safeActiveWidth = activeWidth.isFinite ? max(0, min(width, activeWidth)) : 0
                    
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green.opacity(0.3), .blue.opacity(0.3)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: safeActiveWidth, height: height)
                        .offset(x: safeStartX)
                        .overlay(
                            RoundedRectangle(cornerRadius: height / 2)
                                .fill(.thinMaterial)
                                .opacity(0.3)
                                .frame(width: safeActiveWidth, height: height)
                        )
                    
                    // Simplified time markers with liquid glass styling
                    ForEach(majorTimeMarkers, id: \.self) { time in
                        let position = timeToPosition(time)
                        let safePosition = position.isFinite ? max(0.0, min(1.0, position)) : 0.0
                        let xPos = width * safePosition
                        let safeXPos = xPos.isFinite ? max(0, min(width, xPos)) : 0
                        
                        VStack {
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 4, height: 4)
                                .overlay(
                                    Circle()
                                        .stroke(.primary.opacity(0.3), lineWidth: 0.5)
                                )
                            
                            Text(formatDisplayTime(time))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .position(x: safeXPos, y: height / 2 + 20)
                    }
                    
                    // Open handle with liquid glass
                    sliderHandle(
                        position: openPosition,
                        color: .green,
                        width: width,
                        height: height,
                        isActive: showingOpenTime,
                        dragGesture: DragGesture()
                            .onChanged { value in
                                showingOpenTime = true
                                
                                guard width > 50,
                                      width.isFinite,
                                      value.location.x.isFinite,
                                      value.location.x >= 0 else {
                                    return
                                }
                                
                                let rawPosition = value.location.x / width
                                let newPosition = max(0, min(1, rawPosition))
                                
                                if newPosition.isFinite && newPosition >= 0 && newPosition <= 1 {
                                    openTime = positionToTime(newPosition)
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showingOpenTime = false
                                }
                            }
                    )
                    
                    // Close handle with liquid glass
                    sliderHandle(
                        position: closePosition,
                        color: .red,
                        width: width,
                        height: height,
                        isActive: showingCloseTime,
                        dragGesture: DragGesture()
                            .onChanged { value in
                                showingCloseTime = true
                                
                                guard width > 50,
                                      width.isFinite,
                                      value.location.x.isFinite,
                                      value.location.x >= 0 else {
                                    return
                                }
                                
                                let rawPosition = value.location.x / width
                                let newPosition = max(0, min(1, rawPosition))
                                
                                if newPosition.isFinite && newPosition >= 0 && newPosition <= 1 {
                                    closeTime = positionToTime(newPosition)
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showingCloseTime = false
                                }
                            }
                    )
                }
            }
            .frame(height: 80)
        }
        .liquidGlass(level: .regular, cornerRadius: .large, shadow: .medium)
    }
    
    // MARK: - Helper Views with Liquid Glass
    
    private func timeDisplayCard(time: String, label: String, color: Color, isShowing: Binding<Bool>) -> some View {
        let scale = isShowing.wrappedValue ? 1.05 : 1.0
        let safeScale = scale.isFinite ? max(0.5, min(2.0, scale)) : 1.0
        
        return VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatDisplayTime(time))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(safeScale)
        .animation(.easeInOut(duration: 0.15), value: isShowing.wrappedValue)
    }
    
    private func sliderHandle(position: Double, color: Color, width: CGFloat, height: CGFloat, isActive: Bool, dragGesture: some Gesture) -> some View {
        let safePosition = position.isFinite ? max(0.0, min(1.0, position)) : 0.0
        let xPosition = width * safePosition
        let safeXPosition = xPosition.isFinite ? max(0, min(width, xPosition)) : 0
        let scale = isActive ? 1.1 : 1.0
        let safeScale = scale.isFinite ? max(0.5, min(2.0, scale)) : 1.0
        
        return Circle()
            .fill(.regularMaterial)
            .frame(width: isActive ? 36 : 32, height: isActive ? 36 : 32)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 3)
            )
            .overlay(
                Circle()
                    .fill(color.opacity(0.2))
            )
            .shadow(color: color.opacity(0.3), radius: isActive ? 8 : 4)
            .position(x: safeXPosition, y: height / 2)
            .scaleEffect(safeScale)
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .gesture(dragGesture)
    }
    
    // MARK: - Helper Functions with Comprehensive NaN Protection
    
    private func timeToPosition(_ time: String) -> Double {
        guard let index = timeSlots.firstIndex(of: time),
              timeSlots.count > 1,
              index >= 0,
              index < timeSlots.count else {
            return 0.0
        }
        
        let numerator = Double(index)
        let denominator = Double(timeSlots.count - 1)
        
        guard numerator.isFinite,
              denominator.isFinite,
              denominator > 0 else {
            return 0.0
        }
        
        let position = numerator / denominator
        
        guard position.isFinite,
              position >= 0.0,
              position <= 1.0 else {
            return 0.0
        }
        
        return position
    }
    
    private func positionToTime(_ position: Double) -> String {
        guard position.isFinite,
              position >= 0.0,
              position <= 1.0,
              timeSlots.count > 0 else {
            return "18:00"
        }
        
        let multiplier = Double(timeSlots.count - 1)
        guard multiplier.isFinite, multiplier >= 0 else {
            return "18:00"
        }
        
        let rawIndex = position * multiplier
        guard rawIndex.isFinite else {
            return "18:00"
        }
        
        let index = Int(round(rawIndex))
        let clampedIndex = max(0, min(timeSlots.count - 1, index))
        
        guard clampedIndex >= 0, clampedIndex < timeSlots.count else {
            return "18:00"
        }
        
        return timeSlots[clampedIndex]
    }
    
    private func formatDisplayTime(_ time: String) -> String {
        let components = time.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components.first ?? "0"),
              hour >= 0, hour <= 23 else {
            return "6:00 PM"
        }
        
        if hour == 0 {
            return "12:\(components[1]) AM"
        } else if hour < 12 {
            return "\(hour):\(components[1]) AM"
        } else if hour == 12 {
            return "12:\(components[1]) PM"
        } else {
            return "\(hour - 12):\(components[1]) PM"
        }
    }
}

// MARK: - Simplified Day Hours Editor with Liquid Glass
struct ImprovedDayHoursEditor: View {
    let day: WeekDay
    @Binding var dayHours: DayHours
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(day.displayName)
                    .font(.headline)
                    .frame(width: 80, alignment: .leading)
                
                Spacer()
                
                Toggle("", isOn: $dayHours.isOpen)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            if dayHours.isOpen {
                DualTimeSlider(
                    openTime: Binding(
                        get: { dayHours.openTime },
                        set: { dayHours.openTime = $0 }
                    ),
                    closeTime: Binding(
                        get: { dayHours.closeTime },
                        set: { dayHours.closeTime = $0 }
                    )
                )
            }
        }
        .liquidGlass(
            level: .regular,
            cornerRadius: .large,
            shadow: .medium,
            borderOpacity: dayHours.isOpen ? 0.2 : 0.1
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(dayHours.isOpen ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}
