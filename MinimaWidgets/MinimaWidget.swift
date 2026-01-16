import WidgetKit
import SwiftUI

/// iOS Lock Screen Widget
struct MinimaWidget: Widget {
    let kind: String = "MinimaWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MinimaTimelineProvider()) { entry in
            MinimaWidgetView(entry: entry)
        }
        .configurationDisplayName("Minima")
        .description("Quick access to your AI assistant.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

struct MinimaTimelineEntry: TimelineEntry {
    let date: Date
    let lastThought: String?
}

struct MinimaTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MinimaTimelineEntry {
        MinimaTimelineEntry(date: Date(), lastThought: "Ask me anything...")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MinimaTimelineEntry) -> ()) {
        completion(MinimaTimelineEntry(date: Date(), lastThought: "Ready to help"))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MinimaTimelineEntry>) -> ()) {
        let entry = MinimaTimelineEntry(date: Date(), lastThought: "Tap to open Minima")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct MinimaWidgetView: View {
    var entry: MinimaTimelineEntry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "sparkles")
                    .font(.title2)
            }
            
        case .accessoryRectangular:
            HStack {
                Image(systemName: "sparkles")
                VStack(alignment: .leading) {
                    Text("Minima")
                        .font(.headline)
                    Text(entry.lastThought ?? "Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
        case .systemSmall:
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                Text("Minima")
                    .font(.caption.bold())
                Text(entry.lastThought ?? "Tap to ask")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
            
        default:
            Text("Minima")
        }
    }
}
