import SwiftUI

struct DailyScheduleEditor: View {
    @Binding var schedule: DailySchedule
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(schedule.dayName)
                        .font(.headline)
                        .foregroundColor(schedule.isToday ? .blue : .primary)
                    
                    Text(schedule.displayDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if schedule.isToday {
                        Text("Today")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                Toggle("", isOn: $schedule.isOpen)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            if schedule.isOpen {
                DualTimeSlider(
                    openTime: Binding(
                        get: { schedule.openTime },
                        set: { schedule.openTime = $0 }
                    ),
                    closeTime: Binding(
                        get: { schedule.closeTime },
                        set: { schedule.closeTime = $0 }
                    )
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(schedule.isOpen ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            schedule.isToday ? Color.blue.opacity(0.3) :
                            schedule.isOpen ? Color.green.opacity(0.2) : Color.clear,
                            lineWidth: schedule.isToday ? 2 : 1
                        )
                )
        )
    }
}

#Preview {
    DailyScheduleEditor(schedule: .constant(DailySchedule(date: Date())))
}
