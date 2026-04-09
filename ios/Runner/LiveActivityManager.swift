#if canImport(ActivityKit)
import ActivityKit
import Foundation

@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<ScriptureActivityAttributes>?
    /// 최근 저장된 사진 파일명 (UserDefaults 동기화 지연 방지용)
    public var lastSavedPhotoFilename: String?

    func startActivity(verseText: String, verseRef: String, themeId: String, customPhotoFilename: String?, healthKitAuthorized: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = ScriptureActivityAttributes(
            verseText: verseText,
            verseRef: verseRef,
            themeId: themeId
        )
        let contentState = ScriptureActivityAttributes.ContentState(
            stepCount: 0,
            useTimer: !healthKitAuthorized,
            sessionStartDate: Date(),
            customPhotoFilename: customPhotoFilename
        )

        // 앱 재시작 등으로 currentActivity가 nil이더라도
        // 시스템에 남아 있는 모든 기존 세션을 종료한 뒤 새로 시작
        Task {
            for activity in Activity<ScriptureActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }

            NSLog("[LiveActivityDebug] Attempting to start...")
            do {
                let activity = try Activity<ScriptureActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
                await MainActor.run { self.currentActivity = activity }
                NSLog("[LiveActivityDebug] Success!")
            } catch {
                NSLog("[LiveActivityDebug] Failed to start: \(error.localizedDescription)")
                print("[LiveActivity] Failed to start: \(error.localizedDescription)")
            }
        }
    }

    func updateSteps(_ steps: Int) {
        guard let activity = currentActivity else { return }
        // 타이머 모드일 경우 걸음 수 업데이트 불필요
        guard activity.contentState.useTimer == false else { return }
        Task {
            let updatedState = ScriptureActivityAttributes.ContentState(
                stepCount: steps,
                useTimer: false,
                sessionStartDate: activity.contentState.sessionStartDate,
                customPhotoFilename: activity.contentState.customPhotoFilename
            )
            await activity.update(using: updatedState)
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(dismissalPolicy: .default)
        }
        currentActivity = nil
    }

    var isActive: Bool {
        currentActivity?.activityState == .active
    }
}
#endif
