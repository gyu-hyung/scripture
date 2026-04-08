import Flutter
import UIKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        setupLiveActivityChannel()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupLiveActivityChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else { return }

        let channel = FlutterMethodChannel(
            name: "com.scripture.liveActivity",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            if #available(iOS 16.2, *) {
                self?.handleLiveActivityCall(call: call, result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @available(iOS 16.2, *)
    private func handleLiveActivityCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startSession":
            guard let args = call.arguments as? [String: Any],
                  let verseText = args["verseText"] as? String,
                  let verseRef = args["verseRef"] as? String,
                  let themeId = args["themeId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "verseText, verseRef, themeId required", details: nil))
                return
            }
            NSLog("[LiveActivityDebug] Flutter triggered startSession")

            HealthKitService.shared.requestAuthorization { authorized in
                NSLog("[LiveActivityDebug] HealthKit auth result: \(authorized)")
                DispatchQueue.main.async {
                    LiveActivityManager.shared.startActivity(
                        verseText: verseText,
                        verseRef: verseRef,
                        themeId: themeId,
                        healthKitAuthorized: authorized
                    )
                    if authorized {
                        HealthKitService.shared.fetchTodaySteps { steps in
                            LiveActivityManager.shared.updateSteps(steps)
                        }
                        HealthKitService.shared.onStepsUpdate = { steps in
                            LiveActivityManager.shared.updateSteps(steps)
                        }
                        HealthKitService.shared.startObserving()
                    }
                    result(nil)
                }
            }

        case "stopSession":
            HealthKitService.shared.stopObserving()
            LiveActivityManager.shared.endActivity()
            result(nil)

        case "isSessionActive":
            result(LiveActivityManager.shared.isActive)

        case "saveCustomPhoto":
            guard let args = call.arguments as? [String: Any],
                  let data = args["data"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "data required", details: nil))
                return
            }
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.scripture.scripture"
            ) {
                let fileURL = containerURL.appendingPathComponent("widget_custom_bg.jpg")
                do {
                    // .atomic으로 안전하게 쓰고, 잠금화면에서도 위젯이 읽을 수 있게 .noFileProtection 설정
                    try data.data.write(to: fileURL, options: [.atomic, .noFileProtection])
                    result(nil)
                } catch {
                    result(FlutterError(code: "WRITE_FAILED", message: error.localizedDescription, details: nil))
                }
            } else {
                result(FlutterError(code: "NO_APP_GROUP", message: "App Group container not found", details: nil))
            }

        case "requestHealthKitPermission":
            if HealthKitService.shared.isAuthorizationDetermined {
                // 이미 결정됨 → 설정 앱의 건강 권한 화면으로 이동
                DispatchQueue.main.async {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                result(nil)
            } else {
                // 미결정 → 시스템 다이얼로그 표시
                HealthKitService.shared.requestAuthorization { _ in
                    result(nil)
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
