import WidgetKit
import SwiftUI

// MARK: - Timeline

struct HeadlineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HeadlineEntry {
        HeadlineEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (HeadlineEntry) -> Void) {
        let snap = context.isPreview ? .sample : SharedStore.readSnapshot()
        completion(HeadlineEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HeadlineEntry>) -> Void) {
        let entry = HeadlineEntry(date: .now, snapshot: SharedStore.readSnapshot())
        // Ask iOS to refresh in ~30 min; the app also pushes updates whenever
        // the feed changes via WidgetCenter.reloadAllTimelines().
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Deep link helper

private func articleLink(_ headline: WidgetHeadline) -> URL {
    var comps = URLComponents()
    comps.scheme = AppGroup.urlScheme
    comps.host = "article"
    comps.queryItems = [URLQueryItem(name: "u", value: headline.url)]
    return comps.url ?? URL(string: "\(AppGroup.urlScheme)://article")!
}

// MARK: - Views

struct ZestWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: HeadlineEntry

    var body: some View {
        if entry.snapshot.headlines.isEmpty {
            EmptyWidget()
        } else {
            switch family {
            case .systemSmall: SmallWidget(entry: entry)
            case .systemLarge: ListWidget(entry: entry, max: 6)
            default:           ListWidget(entry: entry, max: 3) // medium
            }
        }
    }
}

private struct SmallWidget: View {
    let entry: HeadlineEntry
    var body: some View {
        let top = entry.snapshot.headlines[0]
        VStack(alignment: .leading, spacing: 6) {
            Label("For you", systemImage: "newspaper.fill")
                .font(.caption2.weight(.bold)).foregroundStyle(.tint)
            Text(top.title).font(.subheadline.weight(.semibold)).lineLimit(4)
            Spacer(minLength: 0)
            Text(top.section.uppercased()).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(articleLink(top))
    }
}

private struct ListWidget: View {
    let entry: HeadlineEntry
    let max: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Your Feed", systemImage: "newspaper.fill")
                    .font(.caption.weight(.bold)).foregroundStyle(.tint)
                Spacer()
                if !entry.snapshot.topInterests.isEmpty {
                    Text(entry.snapshot.topInterests.prefix(3).joined(separator: " · "))
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            ForEach(entry.snapshot.headlines.prefix(max)) { h in
                Link(destination: articleLink(h)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(h.title).font(.subheadline.weight(.medium)).lineLimit(2)
                        Text(h.section.uppercased()).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if h.id != entry.snapshot.headlines.prefix(max).last?.id {
                    Divider()
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct EmptyWidget: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "newspaper").font(.title2).foregroundStyle(.tint)
            Text("Open Zest to load your feed").font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget definition

struct ZestWidget: Widget {
    let kind = "ZestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ZestWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Your Feed")
        .description("Your top personalised stories. Tap one to read it in Zest.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct ZestWidgetBundle: WidgetBundle {
    var body: some Widget { ZestWidget() }
}

// MARK: - Preview sample

extension WidgetSnapshot {
    static let sample = WidgetSnapshot(
        headlines: [
            .init(id: "1", title: "Chancellor unveils surprise budget shake-up", section: "politics",
                  url: "https://www.theguardian.com", publishedAt: .now, score: 88),
            .init(id: "2", title: "New telescope captures sharpest image of distant galaxy", section: "science",
                  url: "https://www.theguardian.com", publishedAt: .now, score: 64),
            .init(id: "3", title: "Late winner sends underdogs into the final", section: "football",
                  url: "https://www.theguardian.com", publishedAt: .now, score: 52)
        ],
        updatedAt: .now,
        topInterests: ["uk", "politics", "science"]
    )
}
