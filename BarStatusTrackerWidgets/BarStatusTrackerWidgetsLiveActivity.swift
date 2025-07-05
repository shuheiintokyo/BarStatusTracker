import ActivityKit
import WidgetKit
import SwiftUI

// Live Activity for future use (disabled for now to avoid errors)
#if canImport(ActivityKit)

struct BarStatusTrackerWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var barName: String
        var status: String
    }

    // Fixed non-changing properties about your activity go here!
    var barId: String
}

@available(iOS 16.1, *)
struct BarStatusTrackerWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BarStatusTrackerWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Bar Status Update")
                    .font(.headline)
                
                Text("\(context.state.barName) is \(context.state.status)")
                    .font(.body)
            }
            .padding()
            .activityBackgroundTint(Color.blue.opacity(0.1))
            .activitySystemActionForegroundColor(Color.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.barName)
                        .font(.headline)
                }
            } compactLeading: {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(context.state.status)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "barstatusapp://bar/\(context.attributes.barId)"))
            .keylineTint(Color.blue)
        }
    }
}

#endif
