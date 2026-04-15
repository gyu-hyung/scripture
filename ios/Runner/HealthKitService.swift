import CoreMotion
import Foundation

/// iOS의 "동작 및 피트니스" 권한(CMPedometer) 기반 만보기.
/// (기존 HealthKit 구현을 대체)
class MotionFitnessService {
    static let shared = MotionFitnessService()

    private let pedometer = CMPedometer()

    var onStepsUpdate: ((Int) -> Void)?

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    var isAuthorizationDetermined: Bool {
        CMPedometer.authorizationStatus() != .notDetermined
    }

    var isAuthorized: Bool {
        CMPedometer.authorizationStatus() == .authorized
    }

    /// 권한을 요청합니다.
    /// CMPedometer는 별도의 request API가 없어서, query를 한 번 호출하여 시스템 팝업을 트리거합니다.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }

        let status = CMPedometer.authorizationStatus()
        if status == .authorized {
            completion(true)
            return
        }
        if status == .denied || status == .restricted {
            completion(false)
            return
        }

        // .notDetermined: query 호출로 권한 팝업 유도
        fetchTodaySteps { _ in
            completion(self.isAuthorized)
        }
    }

    /// 권한이 이미 결정되었는지 확인합니다(허용/거부 포함).
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        completion(isAuthorizationDetermined)
    }

    func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        guard isAvailable else {
            completion(0)
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        pedometer.queryPedometerData(from: startOfDay, to: now) { data, error in
            if let error = error {
                #if DEBUG
                NSLog("[MotionFitnessDebug] fetchTodaySteps error: \(error.localizedDescription)")
                #endif
                completion(0)
                return
            }

            let steps = data?.numberOfSteps.intValue ?? 0
            #if DEBUG
            NSLog("[MotionFitnessDebug] fetchTodaySteps success: \(steps)")
            #endif
            completion(steps)
        }
    }

    func startObserving() {
        guard isAvailable, isAuthorized else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            if let error = error {
                #if DEBUG
                NSLog("[MotionFitnessDebug] startUpdates error: \(error.localizedDescription)")
                #endif
                return
            }
            let steps = data?.numberOfSteps.intValue ?? 0
            DispatchQueue.main.async {
                self?.onStepsUpdate?(steps)
            }
        }
    }

    func stopObserving() {
        pedometer.stopUpdates()
    }
}
