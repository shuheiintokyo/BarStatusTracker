import WidgetKit
import SwiftUI

// Simple home screen widget with modern containerBackground
struct BarStatusTrackerWidgets: Widget {
    let kind: String = "BarStatusTrackerWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            BarStatusTrackerWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Bar Status")
        .description("View bar statuses on your home screen")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let status: String
}

struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), status: "Closed")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), status: "Closed")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), status: "Closed")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct BarStatusTrackerWidgetsEntryView: View {
    var entry: SimpleProvider.Entry

    var body: some View {
        VStack {
            Image(systemName: "building.2")
                .font(.title)
                .foregroundColor(.blue)
            
            Text("Bar Status")
                .font(.headline)
            
            Text(entry.status)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
