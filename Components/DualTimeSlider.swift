import SwiftUI

// MARK: - Clean and Simple Dual Time Slider
struct DualTimeSlider: View {
    @Binding var openTime: String
    @Binding var closeTime: String
    @State private var showingOpenTime = false
    @State private var showingCloseTime = false
    
    private var openPosition: Double {
        timeToPosition(openTime)
    }
    
    private var closePosition: Double {
        timeToPosition(closeTime)
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
            // Clean time display
            HStack {
                timeDisplayCard(time: openTime, label: "Opens", color: .green, isShowing: $showingOpenTime)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                    .font(.title3)
                
                Spacer()
                
                timeDisplayCard(time: closeTime, label: "Closes", color: .red, isShowing: $showingCloseTime)
            }
            
            // Simplified slider track
            GeometryReader { geometry in
                let width = geometry.size.width
                let height: CGFloat = 44
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: height)
                    
                    // Active range
                    let startX = width * min(openPosition, closePosition)
                    let endX = width * max(openPosition, closePosition)
                    let activeWidth = endX - startX
                    
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.green.opacity(0.3), .blue.opacity(0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: activeWidth, height: height)
                        .offset(x: startX)
                    
                    // Simplified time markers
                    ForEach(majorTimeMarkers, id: \.self) { time in
                        let position = timeToPosition(time)
                        
                        VStack {
                            Circle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 3, height: 3)
                            
                            Text(formatDisplayTime(time))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .position(x: width * position, y: height / 2 + 20)
                    }
                    
                    // Open handle
                    sliderHandle(
                        position: openPosition,
                        color: .green,
                        width: width,
                        height: height,
                        isActive: showingOpenTime,
                        dragGesture: DragGesture()
                            .onChanged { value in
                                showingOpenTime = true
                                let newPosition = max(0, min(1, value.location.x / width))
                                openTime = positionToTime(newPosition)
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showingOpenTime = false
                                }
                            }
                    )
                    
                    // Close handle
                    sliderHandle(
                        position: closePosition,
                        color: .red,
                        width: width,
                        height: height,
                        isActive: showingCloseTime,
                        dragGesture: DragGesture()
                            .onChanged { value in
                                showingCloseTime = true
                                let newPosition = max(0, min(1, value.location.x / width))
                                closeTime = positionToTime(newPosition)
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
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func timeDisplayCard(time: String, label: String, color: Color, isShowing: Binding<Bool>) -> some View {
        VStack(spacing: 4) {
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
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isShowing.wrappedValue ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isShowing.wrappedValue)
    }
    
    private func sliderHandle(position: Double, color: Color, width: CGFloat, height: CGFloat, isActive: Bool, dragGesture: some Gesture) -> some View {
        Circle()
            .fill(color)
            .frame(width: isActive ? 36 : 32, height: isActive ? 36 : 32)
            .shadow(color: color.opacity(0.3), radius: isActive ? 8 : 4)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            .position(x: width * position, y: height / 2)
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            .gesture(dragGesture)
    }
    
    // MARK: - Helper Functions
    
    private func timeToPosition(_ time: String) -> Double {
        guard let index = timeSlots.firstIndex(of: time) else { return 0.0 }
        return Double(index) / Double(timeSlots.count - 1)
    }
    
    private func positionToTime(_ position: Double) -> String {
        let index = Int(round(position * Double(timeSlots.count - 1)))
        let clampedIndex = max(0, min(timeSlots.count - 1, index))
        return timeSlots[clampedIndex]
    }
    
    private func formatDisplayTime(_ time: String) -> String {
        let components = time.split(separator: ":")
        guard let hour = Int(components.first ?? "0") else { return time }
        
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

// MARK: - Simplified Day Hours Editor
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(dayHours.isOpen ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(dayHours.isOpen ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}
