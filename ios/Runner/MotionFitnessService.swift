import CoreMotion
import Foundation

/// iOS의 "동작 및 피트니스" 권한(CMPedometer) 기반 만보기.
/// (기존 HealthKit 구현을 대체)
class MotionFitnessService {
    static let shared = MotionFitnessService()

    // lazy를 통해 실제 필요한 시점에 하드웨어 자원(CMPedometer)에 접근
    private var _pedometer: CMPedometer?
    private var pedometer: CMPedometer {
        if _pedometer == nil && isAvailable {
            _pedometer = CMPedometer()
        }
        return _pedometer ?? CMPedometer() // Fallback to avoid crash, but guarded by isAvailable
    }

    var onStepsUpdate: ((Int) -> Void)?

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    var isAuthorizationDetermined: Bool {
        guard isAvailable else { return true } // Not available means we can't do anything, treat as determined
        return CMPedometer.authorizationStatus() != .notDetermined
    }

    var isAuthorized: Bool {
        guard isAvailable else { return false }
        return CMPedometer.authorizationStatus() == .authorized
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
            DispatchQueue.main.async {
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
    }

    /// 이번 주(일~토) 날짜별 걸음 수를 조회합니다.
    func fetchWeeklySteps(completion: @escaping ([[String: Any]]) -> Void) {
        let calendar = Calendar.current
        let today = Date()

        // 이번 주 일요일 구하기
        let weekday = calendar.component(.weekday, from: today) // 1=일, 2=월, ...
        guard let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: calendar.startOfDay(for: today)) else {
            completion((0..<7).map { i in
                let d = calendar.date(byAdding: .day, value: i, to: calendar.startOfDay(for: today))!
                let fmt = ISO8601DateFormatter()
                fmt.formatOptions = [.withFullDate]
                fmt.timeZone = TimeZone.current
                return ["date": fmt.string(from: d), "steps": 0] as [String: Any]
            })
            return
        }

        guard isAvailable, isAuthorized else {
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withFullDate]
            fmt.timeZone = TimeZone.current
            let result = (0..<7).map { i -> [String: Any] in
                let d = calendar.date(byAdding: .day, value: i, to: sunday)!
                return ["date": fmt.string(from: d), "steps": 0]
            }
            completion(result)
            return
        }

        let group = DispatchGroup()
        var results = Array<[String: Any]>(repeating: [:], count: 7)
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        fmt.timeZone = TimeZone.current

        for i in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: i, to: sunday)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dateStr = fmt.string(from: dayStart)

            // 미래 날짜는 건너뛰기
            if dayStart > today {
                results[i] = ["date": dateStr, "steps": 0]
                continue
            }

            group.enter()
            let queryEnd = min(dayEnd, Date())
            pedometer.queryPedometerData(from: dayStart, to: queryEnd) { data, _ in
                let steps = data?.numberOfSteps.intValue ?? 0
                results[i] = ["date": dateStr, "steps": steps]
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }

    func startObserving() {
        guard isAvailable, isAuthorized else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    NSLog("[MotionFitnessDebug] startUpdates error: \(error.localizedDescription)")
                    #endif
                    return
                }
                let steps = data?.numberOfSteps.intValue ?? 0
                self?.onStepsUpdate?(steps)
            }
        }
    }

    func stopObserving() {
        pedometer.stopUpdates()
    }
}
