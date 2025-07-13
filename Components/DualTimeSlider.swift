import SwiftUI

// MARK: - Dual Time Slider for Operating Hours
struct DualTimeSlider: View {
    @Binding var openTime: String
    @Binding var closeTime: String
    @State private var showingOpenTime = false
    @State private var showingCloseTime = false
    
    // Convert time string to slider position (0.0 to 1.0)
    private var openPosition: Double {
        timeToPosition(openTime)
    }
    
    private var closePosition: Double {
        timeToPosition(closeTime)
    }
    
    // Time slots from 6 PM to 6 AM (24 half-hour slots)
    private let timeSlots = [
        "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
        "21:00", "21:30", "22:00", "22:30", "23:00", "23:30",
        "00:00", "00:30", "01:00", "01:30", "02:00", "02:30",
        "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00"
    ]
    
    // Display labels for major time markers
    private let majorTimeMarkers = ["18:00", "21:00", "00:00", "03:00", "06:00"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Time display
            HStack {
                VStack(alignment: .leading) {
                    Text("Opens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDisplayTime(openTime))
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Closes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDisplayTime(closeTime))
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            // Custom dual slider
            ZStack {
                // Background track
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height: CGFloat = 40
                    
                    ZStack(alignment: .leading) {
                        // Full track background
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: height)
                        
                        // Green active area between handles
                        let startX = width * min(openPosition, closePosition)
                        let endX = width * max(openPosition, closePosition)
                        let activeWidth = endX - startX
                        
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color.green.opacity(0.3))
                            .frame(width: activeWidth, height: height)
                            .offset(x: startX)
                        
                        // Time markers
                        ForEach(majorTimeMarkers, id: \.self) { time in
                            let position = timeToPosition(time)
                            
                            VStack(spacing: 2) {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 2, height: height)
                                
                                Text(formatDisplayTime(time))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .position(x: width * position, y: height / 2)
                        }
                        
                        // Open time handle
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 2)
                            .position(x: width * openPosition, y: height / 2)
                            .scaleEffect(showingOpenTime ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: showingOpenTime)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        showingOpenTime = true
                                        let newPosition = max(0, min(1, value.location.x / width))
                                        openTime = positionToTime(newPosition)
                                    }
                                    .onEnded { _ in
                                        showingOpenTime = false
                                    }
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingOpenTime.toggle()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showingOpenTime = false
                                }
                            }
                        
                        // Close time handle
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 2)
                            .position(x: width * closePosition, y: height / 2)
                            .scaleEffect(showingCloseTime ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: showingCloseTime)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        showingCloseTime = true
                                        let newPosition = max(0, min(1, value.location.x / width))
                                        closeTime = positionToTime(newPosition)
                                    }
                                    .onEnded { _ in
                                        showingCloseTime = false
                                    }
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingCloseTime.toggle()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showingCloseTime = false
                                }
                            }
                        
                        // Time popup for open handle
                        if showingOpenTime {
                            Text(formatDisplayTime(openTime))
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .position(x: width * openPosition, y: -15)
                        }
                        
                        // Time popup for close handle
                        if showingCloseTime {
                            Text(formatDisplayTime(closeTime))
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .position(x: width * closePosition, y: -15)
                        }
                    }
                }
            }
            .frame(height: 80) // Extra space for time labels and popups
            
            // Instructions
            Text("Drag the circles to set opening and closing times")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
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

// MARK: - Updated Day Hours Editor with Dual Slider
struct ImprovedDayHoursEditor: View {
    let day: WeekDay
    @Binding var dayHours: DayHours
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .leading)
                
                Spacer()
                
                Toggle("", isOn: $dayHours.isOpen)
                    .labelsHidden()
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
                .padding(.leading, 16)
            }
        }
        .padding()
        .background(dayHours.isOpen ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
