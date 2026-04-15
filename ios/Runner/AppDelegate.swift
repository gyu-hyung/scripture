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
        switch call.method {
        case "startSession":
            guard let args = call.arguments as? [String: Any],
                  let verseText = args["verseText"] as? String,
                  let verseRef = args["verseRef"] as? String,
                  let themeId = args["themeId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "verseText, verseRef, themeId required", details: nil))
                return
            }

            // Live Activity 권한이 거부된 경우 Flutter에 알림
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                result(FlutterError(code: "ACTIVITIES_DISABLED", message: "Live Activities are disabled in Settings", details: nil))
                return
            }

            NSLog("[LiveActivityDebug] Flutter triggered startSession")

            MotionFitnessService.shared.checkAuthorizationStatus { alreadyDetermined in
                let startWithAuth: (Bool) -> Void = { authorized in
                    #if DEBUG
                    NSLog("[LiveActivityDebug] Starting activity with authorized=\(authorized)")
                    #endif

                    // 파일 시스템 플러시 대기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        let defaults = UserDefaults(suiteName: "group.com.jgh.malsseumdonghaeng")
                        let photoFilename = LiveActivityManager.shared.lastSavedPhotoFilename ?? defaults?.string(forKey: "customPhotoFilename")

                        LiveActivityManager.shared.startActivity(
                            verseText: verseText,
                            verseRef: verseRef,
                            themeId: themeId,
                            customPhotoFilename: photoFilename,
                            healthKitAuthorized: authorized
                        ) {
                            // Activity 생성 완료 후 약간의 텀을 두고 걸음 수 fetch (초기화 레이스 컨디션 방지)
                            if authorized {
                                #if DEBUG
                                NSLog("[LiveActivityDebug] Setting up step observation")
                                #endif
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
                    // 이미 권한 결정됨 (허용 또는 거부)
                    startWithAuth(MotionFitnessService.shared.isAuthorized)
                } else {
                    // 최초 실행: 권한 팝업 없이 Live Activity 시작 (걸음 수 대신 타이머)
                    startWithAuth(false)
                }
            }

        case "stopSession":
            MotionFitnessService.shared.stopObserving()
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
            
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jgh.malsseumdonghaeng") {
                // 고유한 파일명 생성을 통해 캐시 문제 완전 해결
                let timestamp = Int(Date().timeIntervalSince1970)
                let filename = "bg_\(timestamp).jpg"
                let fileURL = containerURL.appendingPathComponent(filename)
                
                // 메모리 보호를 위해 이미지 리사이징 및 압축 후 저장
                if saveAndCompressImage(data: data.data, to: fileURL) {
                    let defaults = UserDefaults(suiteName: "group.com.jgh.malsseumdonghaeng")
                    
                    // 기존에 저장된 다른 배경 파일들 삭제 (용량 관리)
                    if let oldFilename = defaults?.string(forKey: "customPhotoFilename") {
                        let oldURL = containerURL.appendingPathComponent(oldFilename)
                        try? FileManager.default.removeItem(at: oldURL)
                    }
                    
                    defaults?.set(filename, forKey: "customPhotoFilename")
                    defaults?.removeObject(forKey: "customPhotoData")
                    defaults?.synchronize()
                    
                    // 메모리 추적 업데이트
                    LiveActivityManager.shared.lastSavedPhotoFilename = filename
                    
                    result(nil)
                } else {
                    result(FlutterError(code: "SAVE_FAILED", message: "Failed to process and save image", details: nil))
                }
            } else {
                result(FlutterError(code: "NO_APP_GROUP", message: "App Group container not found", details: nil))
            }

        case "requestMotionFitnessPermission":
            // 사용자가 명시적으로 권한을 요청하는 경우 (주로 말씀 선택 후)
            // 시스템 팝업을 띄워보고, 이미 선택했다면 아무것도 하지 않음 (설정창 강제 이동 제거)
            MotionFitnessService.shared.requestAuthorization { _ in
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
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
