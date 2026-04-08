#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct ScriptureActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var stepCount: Int
        /// true이면 걸음 수 대신 세션 시작 시각 기준 타이머를 표시
        var useTimer: Bool
        var sessionStartDate: Date
        var customPhotoFilename: String?
    }

    var verseText: String
    var verseRef: String
    var themeId: String
}
#endif
