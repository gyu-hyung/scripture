import HealthKit
import Foundation

class HealthKitService {
    static let shared = HealthKitService()
    let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    var onStepsUpdate: ((Int) -> Void)?

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(false)
            return
        }
        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, _ in
            completion(success)
        }
    }

    /// 현재 걸음 수 읽기 권한 상태를 확인합니다.
    /// iOS 13+에서는 getRequestStatusForAuthorization를 사용할 수 있습니다.
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        guard isAvailable,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(false)
            return
        }
        
        if #available(iOS 13.0, *) {
            healthStore.getRequestStatusForAuthorization(toShare: [], read: [stepType]) { status, error in
                // .shouldRequest 면 아직 미결정 상태인 것임
                completion(status != .shouldRequest)
            }
        } else {
            // 구버전은 기존 방식 유지
            completion(healthStore.authorizationStatus(for: stepType) != .notDetermined)
        }
    }

    var isAuthorizationDetermined: Bool {
        guard isAvailable,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return false
        }
        return healthStore.authorizationStatus(for: stepType) != .notDetermined
    }

    func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        guard isAvailable,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let interval = NSDateComponents()
        interval.day = 1
        
        // 하루를 통째로 집계하는 컬렉션 쿼리 생성
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: startOfDay,
            intervalComponents: interval as DateComponents
        )
        
        query.initialResultsHandler = { _, results, error in
            if let error = error {
                #if DEBUG
                NSLog("[HealthKitDebug] fetchTodaySteps error: \(error.localizedDescription)")
                #endif
                completion(0)
                return
            }

            var totalSteps = 0
            results?.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    totalSteps += Int(sum.doubleValue(for: HKUnit.count()))
                }
            }

            #if DEBUG
            NSLog("[HealthKitDebug] fetchTodaySteps success: \(totalSteps)")
            #endif
            completion(totalSteps)
        }
        
        healthStore.execute(query)
    }

    func startObserving() {
        guard isAvailable,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        // 1. 데이터 변경 시 백그라운드 배달 활성화 (앱이 종료 중이어도 OS가 백그라운드에서 감지 시 앱을 깨움)
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if let error = error {
                #if DEBUG
                NSLog("[HealthKitDebug] enableBackgroundDelivery error: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                NSLog("[HealthKitDebug] enableBackgroundDelivery success: \(success)")
                #endif
            }
        }

        // 2. 옵저버 쿼리 실행
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                #if DEBUG
                NSLog("[HealthKitDebug] Observer error: \(error.localizedDescription)")
                #endif
                return
            }
            // 변경 감지 시 현재 걸음 수 다시 호출
            self?.fetchTodaySteps { steps in
                DispatchQueue.main.async {
                    self?.onStepsUpdate?(steps)
                }
            }
        }
        observerQuery = query
        healthStore.execute(query)
    }

    func stopObserving() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
        }
    }
}
