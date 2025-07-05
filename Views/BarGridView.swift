import SwiftUI

struct BarGridView: View {
    @ObservedObject var barViewModel: BarViewModel
    let isOwnerMode: Bool
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(barViewModel.bars) { bar in
                    BarGridItem(bar: bar, isOwnerMode: isOwnerMode) {
                        barViewModel.selectedBar = bar
                        barViewModel.showingDetail = true
                    }
                }
            }
            .padding()
        }
    }
}
