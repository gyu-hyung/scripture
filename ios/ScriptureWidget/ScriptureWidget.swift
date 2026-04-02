import WidgetKit
import SwiftUI

// MARK: - Data Model
struct VerseEntry: TimelineEntry {
    let date: Date
    let verseText: String
    let reference: String
    let isPinned: Bool
    let themeId: String
}

// MARK: - UserDefaults App Group
private let appGroupId = "group.com.scripture.scripture"
private let keyVerseText = "verse_text"
private let keyVerseReference = "verse_ref"
private let keyIsPinned = "is_pinned"
private let keyWidgetTheme = "widget_theme"

// MARK: - Timeline Provider
struct ScriptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(
            date: Date(),
            verseText: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
            reference: "시편 23:1",
            isPinned: false,
            themeId: "modern_dark"
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
        let themeId = defaults?.string(forKey: keyWidgetTheme) ?? "modern_dark"
        return VerseEntry(date: Date(), verseText: verseText, reference: reference, isPinned: isPinned, themeId: themeId)
    }
}

// MARK: - Widget Views

struct ThemeColors {
    let background: Color
    let text: Color
    let accent: Color
}

func getThemeColors(for themeId: String) -> ThemeColors {
    switch themeId {
    case "minimalist_light":
        return ThemeColors(
            background: Color(red: 0.97, green: 0.98, blue: 0.98),
            text: Color(red: 0.18, green: 0.18, blue: 0.18),
            accent: Color(red: 0.05, green: 0.28, blue: 0.63)
        )
    case "serene_blue":
        return ThemeColors(
            background: Color(red: 0.05, green: 0.28, blue: 0.63),
            text: .white,
            accent: Color(red: 0.73, green: 0.87, blue: 0.98)
        )
    case "nature_green":
        return ThemeColors(
            background: Color(red: 0.18, green: 0.49, blue: 0.20),
            text: .white,
            accent: Color(red: 0.78, green: 0.90, blue: 0.79)
        )
    default: // modern_dark
        return ThemeColors(
            background: Color(red: 0.08, green: 0.08, blue: 0.12),
            text: .white,
            accent: Color(red: 0.72, green: 0.53, blue: 0.04)
        )
    }
}

// 홈화면 Small/Medium 위젯
struct ScriptureHomeWidgetView: View {
    var entry: VerseEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let styles = getThemeColors(for: entry.themeId)
        
        ZStack {
            styles.background

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text(entry.verseText)
                    .font(family == .systemSmall ? .subheadline : .title3)
                    .fontWeight(.medium)
                    .foregroundColor(styles.text)
                    .lineLimit(family == .systemSmall ? 6 : 8)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: false)
                    .multilineTextAlignment(.leading)

                Spacer()

                Text(entry.reference)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(styles.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
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
                    getThemeColors(for: entry.themeId).background,
                    for: .widget
                )
        }
        .configurationDisplayName("성경 말씀")
        .description("매일 성경 말씀을 잠금화면과 홈화면에서 확인하세요.")
        .supportedFamilies(Self.supportedFamilies)
        .contentMarginsDisabled()
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
        isPinned: true,
        themeId: "modern_dark"
    )
}
