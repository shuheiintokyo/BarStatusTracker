import SwiftUI

struct StatusControlView: View {
    let bar: Bar
    @ObservedObject var barViewModel: BarViewModel
    
    // Get the current bar status from the view model to ensure real-time updates
    private var currentBar: Bar? {
        barViewModel.bars.first { $0.id == bar.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Update Status")
                .font(.headline)
            
            HStack(spacing: 10) {
                ForEach(BarStatus.allCases, id: \.self) { status in
                    Button(action: {
                        barViewModel.updateBarStatus(bar, newStatus: status)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: status.icon)
                                .font(.title3)
                            Text(status.displayName)
                                .font(.caption2)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(status == (currentBar?.status ?? bar.status) ? status.color : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(status == (currentBar?.status ?? bar.status) ? .white : .primary)
                    }
                    .scaleEffect(status == (currentBar?.status ?? bar.status) ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentBar?.status)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
