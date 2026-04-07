import HealthKit
import Foundation

class HealthKitService {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()
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

    /// 현재 걸음 수 읽기 권한 상태를 반환합니다.
    /// HealthKit은 privacy 정책상 denied와 authorized를 구분해 외부에 노출하지 않으므로
    /// notDetermined / determined 두 가지로만 분류합니다.
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
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            completion(steps)
        }
        healthStore.execute(query)
    }

    func startObserving() {
        guard isAvailable,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
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
