import Flutter
import UIKit
import CoreMotion
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
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // super.application 이후에 채널을 설정하여 window가 확보된 상태에서 진행
        setupLiveActivityChannel()
        
        return result
    }

    private func setupLiveActivityChannel() {
        // 백그라운드(Headless) 실행 시에는 window가 nil일 수 있으므로 무한 재시도를 하지 않습니다.
        guard let controller = window?.rootViewController as? FlutterViewController else {
            #if DEBUG
            NSLog("[LiveActivityDebug] window.rootViewController is nil (Headless or background launch). Skipping channel setup.")
            #endif
            return
        }

        let channel = FlutterMethodChannel(
            name: "com.jgh.scripture.liveActivity",
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
        // 모든 로직을 전역 에러 제어로 감싸서 크래시 방어
        do {
            switch call.method {
            case "startSession":
                guard let args = call.arguments as? [String: Any],
                      let verseText = args["verseText"] as? String,
                      let verseRef = args["verseRef"] as? String,
                      let themeId = args["themeId"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "verseText, verseRef, themeId required", details: nil))
                    return
                }

                guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                    result(FlutterError(code: "ACTIVITIES_DISABLED", message: "Live Activities are disabled", details: nil))
                    return
                }

                MotionFitnessService.shared.checkAuthorizationStatus { alreadyDetermined in
                    let startWithAuth: (Bool) -> Void = { authorized in
                        // 파일 시스템 대기 (권한 변경 직후의 시스템 불안정기 대비)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let defaults = UserDefaults(suiteName: "group.com.jgh.malsseumdonghaeng")
                            let photoFilename = LiveActivityManager.shared.lastSavedPhotoFilename ?? defaults?.string(forKey: "customPhotoFilename")

                            LiveActivityManager.shared.startActivity(
                                verseText: verseText,
                                verseRef: verseRef,
                                themeId: themeId,
                                customPhotoFilename: photoFilename,
                                healthKitAuthorized: authorized
                            ) {
                                if authorized {
                                    MotionFitnessService.shared.onStepsUpdate = { steps in
                                        LiveActivityManager.shared.updateSteps(steps)
                                    }
                                    MotionFitnessService.shared.startObserving()
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        MotionFitnessService.shared.fetchTodaySteps { steps in
                                            LiveActivityManager.shared.updateSteps(steps)
                                        }
                                    }
                                }
                            }
                            result(nil)
                        }
                    }

                    if alreadyDetermined {
                        startWithAuth(MotionFitnessService.shared.isAuthorized)
                    } else {
                        startWithAuth(false)
                    }
                }

            case "stopSession":
                MotionFitnessService.shared.stopObserving()
                LiveActivityManager.shared.endActivity()
                result(nil)

            case "isSessionActive":
                result(LiveActivityManager.shared.isActive)

            case "isLiveActivityEnabled":
                result(ActivityAuthorizationInfo().areActivitiesEnabled)

            case "saveCustomPhoto":
                guard let args = call.arguments as? [String: Any],
                      let data = args["data"] as? FlutterStandardTypedData else {
                    result(FlutterError(code: "INVALID_ARGS", message: "data required", details: nil))
                    return
                }
                
                if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jgh.malsseumdonghaeng") {
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let filename = "bg_\(timestamp).jpg"
                    let fileURL = containerURL.appendingPathComponent(filename)
                    
                    if saveAndCompressImage(data: data.data, to: fileURL) {
                        let defaults = UserDefaults(suiteName: "group.com.jgh.malsseumdonghaeng")
                        if let oldFilename = defaults?.string(forKey: "customPhotoFilename") {
                            let oldURL = containerURL.appendingPathComponent(oldFilename)
                            try? FileManager.default.removeItem(at: oldURL)
                        }
                        defaults?.set(filename, forKey: "customPhotoFilename")
                        defaults?.removeObject(forKey: "customPhotoData")
                        defaults?.synchronize()
                        LiveActivityManager.shared.lastSavedPhotoFilename = filename
                        result(nil)
                    } else {
                        result(FlutterError(code: "SAVE_FAILED", message: "Failed to save image", details: nil))
                    }
                } else {
                    result(FlutterError(code: "NO_APP_GROUP", message: "App Group container not found", details: nil))
                }

            case "fetchWeeklySteps":
                MotionFitnessService.shared.fetchWeeklySteps { data in
                    result(data)
                }

            case "requestMotionFitnessPermission":
                MotionFitnessService.shared.requestAuthorization { _ in
                    result(nil)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            #if DEBUG
            NSLog("[LiveActivityDebug] Critical crash prevented in handleLiveActivityCall: \(error.localizedDescription)")
            #endif
            result(FlutterError(code: "CRITICAL_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    /// 라이브 액티비티의 초저용량 메모리 제한(15-30MB)을 위해 이미지를 강제로 리사이징 및 압축합니다.
    private func saveAndCompressImage(data: Data, to url: URL) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        
        // 메모리 제한에 절대적으로 안전하도록 360px로 극한의 리사이징
        let maxDimension: CGFloat = 360
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // 초경량 렌더링 포맷 설정
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // 압축률을 0.5로 높여 파일 크기 최소화
        guard let finalData = resizedImage.jpegData(compressionQuality: 0.5) else { return false }
        
        do {
            try finalData.write(to: url)
            return true
        } catch {
            return false
        }
    }
}
