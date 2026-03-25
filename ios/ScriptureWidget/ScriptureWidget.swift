import WidgetKit
import SwiftUI

// MARK: - Data Model
struct VerseEntry: TimelineEntry {
    let date: Date
    let verseText: String
    let reference: String
    let isPinned: Bool
}

// MARK: - UserDefaults App Group
private let appGroupId = "group.com.scripture.scripture"
private let keyVerseText = "scripture_verse_text"
private let keyVerseReference = "scripture_verse_reference"
private let keyIsPinned = "scripture_is_pinned"

// MARK: - Timeline Provider
struct ScriptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(
            date: Date(),
            verseText: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
            reference: "시편 23:1",
            isPinned: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let entry = loadEntry()
        // 매일 자정에 갱신
        let nextUpdate = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> VerseEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let verseText = defaults?.string(forKey: keyVerseText) ?? "여호와는 나의 목자시니 내게 부족함이 없으리로다"
        let reference = defaults?.string(forKey: keyVerseReference) ?? "시편 23:1"
        let isPinned = defaults?.bool(forKey: keyIsPinned) ?? false
        return VerseEntry(date: Date(), verseText: verseText, reference: reference, isPinned: isPinned)
    }
}

// MARK: - Widget Views

// 홈화면 Small/Medium 위젯
struct ScriptureHomeWidgetView: View {
    var entry: VerseEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(Color(red: 0.72, green: 0.53, blue: 0.04))
                        .font(.caption2)
                    if entry.isPinned {
                        Text("내가 설정한 말씀")
                            .font(.caption2)
                            .foregroundColor(Color(red: 0.72, green: 0.53, blue: 0.04))
                    } else {
                        Text("오늘의 말씀")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }

                Spacer()

                Text(entry.verseText)
                    .font(family == .systemSmall ? .caption : .body)
                    .foregroundColor(.white)
                    .lineLimit(family == .systemSmall ? 4 : 6)
                    .fixedSize(horizontal: false, vertical: false)

                Spacer()

                Text(entry.reference)
                    .font(.caption2)
                    .foregroundColor(Color(red: 0.72, green: 0.53, blue: 0.04))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
        }
    }
}

// 잠금화면 Rectangular 위젯
struct ScriptureLockRectangularView: View {
    var entry: VerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.reference)
                .font(.caption2)
                .fontWeight(.semibold)
            Text(entry.verseText)
                .font(.caption2)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 잠금화면 Inline 위젯
struct ScriptureLockInlineView: View {
    var entry: VerseEntry

    var body: some View {
        Text("\(entry.reference) \(entry.verseText)")
            .lineLimit(1)
    }
}

// MARK: - Entry View Router
struct ScriptureWidgetEntryView: View {
    var entry: VerseEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            ScriptureLockRectangularView(entry: entry)
        case .accessoryInline:
            ScriptureLockInlineView(entry: entry)
        default:
            ScriptureHomeWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct ScriptureVerseWidget: Widget {
    let kind: String = "ScriptureWidget"

    static var supportedFamilies: [WidgetFamily] {
        #if os(iOS)
        return [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline]
        #else
        return [.systemSmall, .systemMedium]
        #endif
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScriptureProvider()) { entry in
            ScriptureWidgetEntryView(entry: entry)
                .containerBackground(
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    for: .widget
                )
        }
        .configurationDisplayName("성경 말씀")
        .description("매일 성경 말씀을 잠금화면과 홈화면에서 확인하세요.")
        .supportedFamilies(Self.supportedFamilies)
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    ScriptureVerseWidget()
} timeline: {
    VerseEntry(
        date: .now,
        verseText: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
        reference: "시편 23:1",
        isPinned: true
    )
}
