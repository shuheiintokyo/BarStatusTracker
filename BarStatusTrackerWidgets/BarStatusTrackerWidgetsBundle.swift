import WidgetKit
import SwiftUI

@main
struct BarStatusTrackerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Home screen widget (only this one works for now)
        BarStatusTrackerWidgets()
        
        // Control Center widget is disabled until we implement it properly
        // We'll focus on the main app first, then add Control Center widgets later
        
        // Live Activity is also disabled for now
        // BarStatusTrackerWidgetsLiveActivity()
    }
}
