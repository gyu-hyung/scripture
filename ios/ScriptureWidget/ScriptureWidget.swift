import WidgetKit
import SwiftUI
import UIKit
#if canImport(ActivityKit)
import ActivityKit
#endif

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

// MARK: - Custom Photo Helper

func loadCustomPhoto() -> Image? {
    guard let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.scripture.scripture"
    ) else { return nil }
    let fileURL = containerURL.appendingPathComponent("widget_custom_bg.jpg")
    guard let uiImage = UIImage(contentsOfFile: fileURL.path) else { return nil }
    return Image(uiImage: uiImage)
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
    case "custom_photo":
        // 사진 위에 흰색 텍스트 사용 (배경은 ZStack에서 별도 처리)
        return ThemeColors(
            background: Color(red: 0.08, green: 0.08, blue: 0.12),
            text: .white,
            accent: Color(white: 0.92)
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
        let isPhoto = entry.themeId == "custom_photo"

        ZStack {
            // 배경
            if isPhoto, let photo = loadCustomPhoto() {
                photo
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                styles.background
            }

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
    let kind: String = "ScriptureWidgetV2"

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

// MARK: - Live Activity UI (Consolidated)

#if canImport(ActivityKit)
@available(iOS 16.2, *)
struct ScriptureDynamicDataView: View {
    let state: ScriptureActivityAttributes.ContentState
    let accentColor: Color
    let textColor: Color

    var body: some View {
        if state.useTimer {
            // 권한 거절 시: 세션 경과 타이머
            VStack(alignment: .center, spacing: 2) {
                Text("⏳")
                    .font(.system(size: 14))
                Text(timerInterval: state.sessionStartDate...state.sessionStartDate.addingTimeInterval(8 * 3600),
                     countsDown: false)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                Text("동행 중")
                    .font(.system(size: 9))
                    .foregroundColor(textColor.opacity(0.6))
            }
            .frame(width: 60)
        } else {
            // 권한 허용 시: 걸음 수
            VStack(alignment: .center, spacing: 2) {
                Text("👣")
                    .font(.system(size: 16))
                Text(state.stepCount >= 1000
                     ? String(format: "%.1fk", Double(state.stepCount) / 1000.0)
                     : "\(state.stepCount)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
                Text("걸음")
                    .font(.system(size: 9))
                    .foregroundColor(textColor.opacity(0.6))
            }
            .frame(width: 52)
        }
    }
}

@available(iOS 16.2, *)
struct ScriptureLiveActivityLockView: View {
    let context: ActivityViewContext<ScriptureActivityAttributes>

    var body: some View {
        let theme = getThemeColors(for: context.attributes.themeId)
        let isPhoto = context.attributes.themeId == "custom_photo"

        ZStack {
            // 배경 레이어
            if isPhoto {
                if let photo = loadCustomPhoto() {
                    photo
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    theme.background
                }
            } else {
                theme.background
            }

            // 메인 컨텐츠 레이어
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    // 좌측: 말씀 (참조 + 본문)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.attributes.verseRef)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isPhoto ? .white.opacity(0.85) : theme.accent)
                            .lineLimit(1)

                        Text(context.attributes.verseText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isPhoto ? .white : theme.text)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 우측: 걸음 수 또는 타이머
                    ScriptureDynamicDataView(
                        state: context.state,
                        accentColor: isPhoto ? .white.opacity(0.85) : theme.accent,
                        textColor: isPhoto ? .white : theme.text
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

@available(iOS 16.2, *)
struct ScriptureActivityConfiguration: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScriptureActivityAttributes.self) { context in
            ScriptureLiveActivityLockView(context: context)
                .activityBackgroundTint(Color.clear)
        } dynamicIsland: { context in
            let theme = getThemeColors(for: context.attributes.themeId)

            return DynamicIsland {
                // Expanded (길게 터치 시)
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.attributes.verseRef)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.accent)

                        Text(context.attributes.verseText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.text)
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ScriptureDynamicDataView(
                        state: context.state,
                        accentColor: theme.accent,
                        textColor: theme.text
                    )
                    .padding(.trailing, 4)
                }
            } compactLeading: {
                // Compact 좌측: 책 아이콘
                Text("📖")
                    .font(.caption2)
            } compactTrailing: {
                // Compact 우측: 걸음 수 또는 타이머
                if context.state.useTimer {
                    Text("⏳")
                        .font(.caption2)
                } else {
                    Text(context.state.stepCount >= 1000
                         ? String(format: "%.1fk", Double(context.state.stepCount) / 1000.0)
                         : "\(context.state.stepCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accent)
                        .monospacedDigit()
                }
            } minimal: {
                // Minimal: 아이콘만
                Text("📖")
                    .font(.caption2)
            }
            .keylineTint(theme.accent)
        }
    }
}
#endif
