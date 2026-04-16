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
private let appGroupId = "group.com.jgh.malsseumdonghaeng"
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

func loadCustomPhoto(filename: String? = nil) -> Image? {
    let appGroupId = "group.com.jgh.malsseumdonghaeng"
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
        return nil
    }
    
    // 1. 가장 권장되는 방식: 인자로 전달받은 고유 파일명 로드 (캐시 문제 없음)
    if let filename = filename {
        let fileURL = containerURL.appendingPathComponent(filename)
        if let data = try? Data(contentsOf: fileURL, options: .alwaysMapped),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
    }
    
    // 2. 차선책: 고정된 위치의 파일 직접 로드
    let fixedFileURL = containerURL.appendingPathComponent("widget_custom_bg.jpg")
    if let data = try? Data(contentsOf: fixedFileURL, options: .alwaysMapped),
       let uiImage = UIImage(data: data) {
        return Image(uiImage: uiImage)
    }
    
    // 3. 하위 호환성: UserDefaults에 저장된 파일명이 있을 경우 시도
    if let defaults = UserDefaults(suiteName: appGroupId),
       let defaultsFilename = defaults.string(forKey: "customPhotoFilename") {
        let legacyFileURL = containerURL.appendingPathComponent(defaultsFilename)
        if let data = try? Data(contentsOf: legacyFileURL, options: .alwaysMapped),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
    }
    
    // 4. 최후의 보루: 구형 방식(UserDefaults 직접 저장) 체크
    if let data = UserDefaults(suiteName: appGroupId)?.data(forKey: "customPhotoData"),
       let uiImage = UIImage(data: data) {
        return Image(uiImage: uiImage)
    }
    
    return nil
}

func getThemeColors(for themeId: String) -> ThemeColors {
    switch themeId {
    case "pure_white":
        return ThemeColors(
            background: .white,
            text: Color(red: 0.18, green: 0.18, blue: 0.18),
            accent: Color(red: 0.05, green: 0.28, blue: 0.63)
        )
    case "pastel_red":
        return ThemeColors(
            background: Color(red: 0.99, green: 0.89, blue: 0.93),
            text: Color(red: 0.53, green: 0.05, blue: 0.31),
            accent: Color(red: 0.94, green: 0.38, blue: 0.57)
        )
    case "pastel_orange":
        return ThemeColors(
            background: Color(red: 1.0, green: 0.95, blue: 0.88),
            text: Color(red: 0.90, green: 0.32, blue: 0.0),
            accent: Color(red: 1.0, green: 0.72, blue: 0.30)
        )
    case "pastel_yellow":
        return ThemeColors(
            background: Color(red: 1.0, green: 0.99, blue: 0.91),
            text: Color(red: 0.96, green: 0.50, blue: 0.09),
            accent: Color(red: 1.0, green: 0.95, blue: 0.46)
        )
    case "pastel_green":
        return ThemeColors(
            background: Color(red: 0.91, green: 0.96, blue: 0.91),
            text: Color(red: 0.11, green: 0.37, blue: 0.13),
            accent: Color(red: 0.51, green: 0.78, blue: 0.52)
        )
    case "pastel_teal":
        return ThemeColors(
            background: Color(red: 0.88, green: 0.95, blue: 0.95),
            text: Color(red: 0.0, green: 0.30, blue: 0.25),
            accent: Color(red: 0.30, green: 0.71, blue: 0.67)
        )
    case "pastel_blue":
        return ThemeColors(
            background: Color(red: 0.89, green: 0.95, blue: 0.99),
            text: Color(red: 0.05, green: 0.28, blue: 0.63),
            accent: Color(red: 0.39, green: 0.71, blue: 0.96)
        )
    case "pastel_indigo":
        return ThemeColors(
            background: Color(red: 0.91, green: 0.92, blue: 0.96),
            text: Color(red: 0.10, green: 0.14, blue: 0.49),
            accent: Color(red: 0.47, green: 0.53, blue: 0.80)
        )
    case "pastel_purple":
        return ThemeColors(
            background: Color(red: 0.95, green: 0.90, blue: 0.96),
            text: Color(red: 0.29, green: 0.08, blue: 0.55),
            accent: Color(red: 0.73, green: 0.41, blue: 0.78)
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
                    .foregroundColor(isPhoto ? .white : styles.text)
                    .lineLimit(family == .systemSmall ? 6 : 8)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: false)
                    .multilineTextAlignment(.leading)
                    .shadow(color: isPhoto ? .black.opacity(0.8) : .clear, radius: 2, x: 0, y: 1)

                Spacer()

                Text(entry.reference)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isPhoto ? .white.opacity(0.9) : styles.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .shadow(color: isPhoto ? .black.opacity(0.8) : .clear, radius: 2, x: 0, y: 1)
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
    var isHorizontal: Bool = false

    var body: some View {
        if state.useTimer {
            // 타이머 표시 (HealthKit 미허용 시)
            HStack(alignment: .center, spacing: 4) {
                Text("⏱️")
                    .font(.system(size: isHorizontal ? 12 : 14))
                Text(state.sessionStartDate, style: .timer)
                    .font(.system(size: isHorizontal ? 11 : 11, weight: .bold))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
            }
            .frame(width: isHorizontal ? 50 : 40, alignment: .trailing)
        } else {
            // 권한 허용 시: 걸음 수
            if isHorizontal {
                HStack(alignment: .center, spacing: 4) {
                    Text("👣")
                        .font(.system(size: 12))
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    Text(state.stepCount >= 1000
                         ? String(format: "%.1fk", Double(state.stepCount) / 1000.0)
                         : "\(state.stepCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            } else {
                VStack(alignment: .center, spacing: 2) {
                    Text("👣")
                        .font(.system(size: 16))
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    Text(state.stepCount >= 1000
                         ? String(format: "%.1fk", Double(state.stepCount) / 1000.0)
                         : "\(state.stepCount)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentColor)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    Text("걸음")
                        .font(.system(size: 9))
                        .foregroundColor(textColor.opacity(0.6))
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
                .frame(width: 52)
            }
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
                if let photo = loadCustomPhoto(filename: context.state.customPhotoFilename) {
                    photo
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .overlay(Color.black.opacity(0.4))
                } else {
                    // 진단용 아이콘: 사진 테마인데 로딩 실패 시 표시
                    theme.background
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("⚠️")
                                .font(.system(size: 10))
                                .opacity(0.3)
                                .padding(8)
                        }
                    }
                }
            } else {
                theme.background
            }

            // 메인 컨텐츠 레이어
            ZStack {
                // 말씀 (참조 + 본문) — 위젯 전체 기준 정중앙
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.verseRef)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isPhoto ? .white.opacity(0.85) : theme.accent)
                        .lineLimit(1)
                        .shadow(color: isPhoto ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)

                    Text(context.attributes.verseText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isPhoto ? .white : theme.text)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.6)
                        .truncationMode(.tail)
                        .shadow(color: isPhoto ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                }
                .privacySensitive(false)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                // 걸음수/타이머 — 우측 하단 (별도 레이어, 말씀 중앙에 영향 없음)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ScriptureDynamicDataView(
                            state: context.state,
                            accentColor: isPhoto ? .white.opacity(0.85) : theme.accent,
                            textColor: isPhoto ? .white : theme.text,
                            isHorizontal: true
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            let isPhoto = context.attributes.themeId == "custom_photo"

            return DynamicIsland {
                // Expanded (길게 터치 시)
                DynamicIslandExpandedRegion(.center) {
                    ZStack {
                        // 말씀 (참조 + 본문) — 최대한 잠금 위젯(ScriptureLiveActivityLockView)과 동일하게 구성
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.attributes.verseRef)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isPhoto ? .white.opacity(0.85) : theme.accent)
                                .lineLimit(1)
                                .shadow(color: isPhoto ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)

                            Text(context.attributes.verseText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white) // 다이나믹 아일랜드는 항상 배경이 검정이므로 흰색 고정
                                .multilineTextAlignment(.leading)
                                .lineSpacing(2)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.6)
                                .truncationMode(.tail)
                                .shadow(color: isPhoto ? .black.opacity(0.7) : .clear, radius: 1, x: 0, y: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)

                        // 걸음수/타이머 — 우측 하단 (잠금 위젯과 동일한 위치/패딩)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ScriptureDynamicDataView(
                                    state: context.state,
                                    accentColor: isPhoto ? .white.opacity(0.85) : theme.accent,
                                    textColor: .white,
                                    isHorizontal: true
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                        }
                    }
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
