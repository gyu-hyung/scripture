#if canImport(ActivityKit)
import ActivityKit
import Foundation

@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<ScriptureActivityAttributes>?
    /// 최근 저장된 사진 파일명 (UserDefaults 동기화 지연 방지용)
    public var lastSavedPhotoFilename: String?

    func startActivity(verseText: String, verseRef: String, themeId: String, customPhotoFilename: String?, healthKitAuthorized: Bool, completion: (() -> Void)? = nil) {
        // Live Activity 권한이 꺼져 있으면 조용히 리턴 (다른 프리미엄 앱들처럼 크래시나 강제 팝업 방지)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            #if DEBUG
            NSLog("[LiveActivityDebug] Live Activities are disabled. Skipping start.")
            #endif
            completion?()
            return
        }

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

            do {
                #if DEBUG
                NSLog("[LiveActivityDebug] Attempting to request new Activity...")
                #endif
                let activity = try Activity<ScriptureActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
                await MainActor.run { self.currentActivity = activity }
                #if DEBUG
                NSLog("[LiveActivityDebug] Activity successfully started!")
                #endif
            } catch {
                #if DEBUG
                NSLog("[LiveActivityDebug] Failed to request Activity: \(error.localizedDescription)")
                #endif
            }

            await MainActor.run { completion?() }
        }
    }

    func updateSteps(_ steps: Int) {
        guard let activity = currentActivity else { return }
        // 타이머 모드일 경우 걸음 수 업데이트 불필요
        guard activity.contentState.useTimer == false else { return }
        Task {
            do {
                let updatedState = ScriptureActivityAttributes.ContentState(
                    stepCount: steps,
                    useTimer: false,
                    sessionStartDate: activity.contentState.sessionStartDate,
                    customPhotoFilename: activity.contentState.customPhotoFilename
                )
                try await activity.update(using: updatedState)
            } catch {
                #if DEBUG
                NSLog("[LiveActivityDebug] Failed to update steps: \(error.localizedDescription)")
                #endif
            }
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }
        Task {
            do {
                await activity.end(dismissalPolicy: .immediate)
            } catch {
                #if DEBUG
                NSLog("[LiveActivityDebug] Failed to end activity: \(error.localizedDescription)")
                #endif
            }
        }
        currentActivity = nil
    }

    var isActive: Bool {
        currentActivity?.activityState == .active
    }
}
#endif
