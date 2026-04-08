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
                    let defaults = UserDefaults(suiteName: "group.com.scripture.scripture")
                    let photoFilename = defaults?.string(forKey: "customPhotoFilename")
                    
                    LiveActivityManager.shared.startActivity(
                        verseText: verseText,
                        verseRef: verseRef,
                        themeId: themeId,
                        customPhotoFilename: photoFilename,
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
            
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.scripture.scripture") {
                // 고유한 파일명 생성을 통해 캐시 문제 완전 해결
                let timestamp = Int(Date().timeIntervalSince1970)
                let filename = "bg_\(timestamp).jpg"
                let fileURL = containerURL.appendingPathComponent(filename)
                
                // 메모리 보호를 위해 이미지 리사이징 및 압축 후 저장
                if saveAndCompressImage(data: data.data, to: fileURL) {
                    let defaults = UserDefaults(suiteName: "group.com.scripture.scripture")
                    
                    // 기존에 저장된 다른 배경 파일들 삭제 (용량 관리)
                    if let oldFilename = defaults?.string(forKey: "customPhotoFilename") {
                        let oldURL = containerURL.appendingPathComponent(oldFilename)
                        try? FileManager.default.removeItem(at: oldURL)
                    }
                    
                    defaults?.set(filename, forKey: "customPhotoFilename")
                    defaults?.removeObject(forKey: "customPhotoData")
                    defaults?.synchronize()
                    result(nil)
                } else {
                    result(FlutterError(code: "SAVE_FAILED", message: "Failed to process and save image", details: nil))
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

    /// 라이브 액티비티의 초저용량 메모리 제한(15-30MB)을 위해 이미지를 강제로 리사이징 및 압축합니다.
    private func saveAndCompressImage(data: Data, to url: URL) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        
        let maxDimension: CGFloat = 600
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        guard let finalData = resizedImage.jpegData(compressionQuality: 0.6) else { return false }
        
        do {
            try finalData.write(to: url)
            return true
        } catch {
            return false
        }
    }
}
