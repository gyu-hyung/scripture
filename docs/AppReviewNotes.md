# App Store Connect - 심사 노트 (Review Notes)

이 문서는 App Store Connect에서 빌드 제출 시 "심사 노트" 섹션에 붙여넣기할 내용입니다.

---

## 📌 한국 앱스토어 제출용

```
=================================================
앱 이름: 말씀 동행
앱 설명: iOS Live Activities를 활용한 성경 말씀 잠금화면 위젯
=================================================

[앱 기능 설명]

이 앱은 iOS의 Live Activities (실시간 현황) 기능을 사용하여
잠금화면 하단에 성경 말씀과 실시간 걸음 수를 표시합니다.

핵심 기술:
- iOS ActivityKit (Live Activities): iPhone 14+ Dynamic Island 완벽 지원
- HealthKit 연동: 사용자의 일일 걸음 수를 실시간으로 추적
- 로컬 저장만 사용: 모든 데이터는 기기 내부에서만 처리, 서버 연결 없음
- 8시간 세션: 일과 시작부터 종료까지 말씀과 동행

[HealthKit 권한 처리]

1. 권한 허용 시:
   - 실시간 걸음 수가 잠금화면에 업데이트됨
   - 앱이 백그라운드에서도 HealthKit 데이터 감시

2. 권한 거절 시:
   - 에러 없이 자동으로 "세션 진행 시간" 타이머로 전환
   - 사용자는 권한 거절 여부와 관계없이 Live Activity 정상 사용
   - 타이머도 실시간으로 초 단위로 업데이트되므로
     Apple의 Live Activities 가이드라인(동적 데이터 필수) 충족

[Dynamic Island 구현]

iPhone 14+ 사용자:
- Compact View (기본): 좌측 📖 아이콘 + 우측 걸음 수/⏳ 타이머
- Expanded View (길게 터치): 전체 성경 구절 + 걸음 수/타이머
- Minimal View (다른 앱과 충돌): 📖 아이콘만 표시

iPhone 13 이하:
- 잠금화면 작은 위젯 영역에 구절 표시
- 데이터 갱신 시 상단 배너로 알림

[서버 없음 보장]

- pushType = nil (서버 푸시 없음)
- UserDefaults App Group으로만 데이터 공유
- HealthKit은 기기 로컬 데이터만 읽음
- 완전 오프라인 작동 가능

[앱 심사 권장 테스트 방법]

1. 일반 테스트:
   - 앱 설치 후 "시작" 버튼 클릭
   - 성경 말씀 1개 선택
   - HealthKit 권한 팝업 → "이 앱만 허용" 선택
   - 30초 대기 후 잠금화면 확인
   - 파란색 바에 구절 + 👣 걸음 수 표시됨

2. Dynamic Island 테스트 (iPhone 14+ 필수):
   - 상태 바(Dynamic Island) 길게 터치
   - Expanded View에서 전체 구절 및 걸음 수 확인
   - 상태 바 밖을 터치해 닫기
   - Compact View에서 좌측(📖) + 우측(걸음 수) 확인
   - 30초 더 대기 후 우측 숫자 증가 확인 (실시간 업데이트)

3. HealthKit 권한 거절 테스트:
   - 앱 완전 삭제 후 재설치
   - "시작" 클릭 후 HealthKit 권한 팝업 → "허용 안 함" 선택
   - 30초 대기 후 잠금화면 확인
   - 👣(걸음) 대신 ⏱️(타이머) 표시됨
   - 타이머가 초 단위로 계속 증가함 (에러 없음)

4. 커스텀 배경 이미지 (선택사항):
   - 앱 설정에서 "배경 사진 선택"
   - 앨범에서 이미지 선택
   - Live Activity 재시작
   - 잠금화면에 선택한 이미지가 배경으로 표시됨
   - 텍스트가 검정 오버레이 위에서 읽기 쉬움

[기술 스택]

- 주 언어: Flutter (Dart), iOS native (Swift)
- 프레임워크: ActivityKit, HealthKit, UserDefaults
- 최소 지원 버전: iOS 16.2

[추가 참고 사항]

- 이 앱은 HealthKit API를 "정적 배경" 용도가 아닌
  "실시간 변화하는 사용자 활동 데이터"로 활용하므로
  Apple의 Live Activities 심사 가이드라인을 완벽히 준수합니다.

- 만보기와 타이머 중 하나는 항상 실시간으로 업데이트되므로
  Live Activity의 "동적 데이터" 요구사항을 만족합니다.

- 개인 정보 보호: HealthKit 데이터는 기기에서만 읽으며,
  외부로 전송되지 않습니다.

=================================================
```

---

## 🌍 글로벌(English) 앱스토어 제출용

```
=================================================
App Name: Scripture Walking (말씀 동행)
Description: Lock Screen Widget with Real-Time Step Tracking
=================================================

[App Overview]

This app leverages iOS Live Activities to display Scripture verses
and real-time step count on the lock screen during your daily routine.
It provides an inspiring companion experience combining spiritual
reflection with physical activity.

Core Technology:
- iOS ActivityKit (Live Activities): Full Dynamic Island support on iPhone 14+
- HealthKit Integration: Real-time daily step count tracking
- Local-Only Data: All data remains on-device, no server communication
- 8-Hour Session: Designed to accompany users from morning routine start
  through work day

[HealthKit Permission Handling]

1. Permission Allowed:
   - Real-time step count updates on lock screen
   - App monitors HealthKit data in background using enableBackgroundDelivery()
   - Seamless continuous tracking

2. Permission Denied:
   - App automatically switches to Session Timer mode (no errors)
   - Users can still use Live Activity fully, with elapsed time display
   - Timer updates in real-time (every second), fulfilling Apple's requirement
     that Live Activities must show live, changing data (not static content)
   - This ensures the app is always functionally dynamic

[Dynamic Island Implementation]

For iPhone 14+ users:
- Compact View (default): Left 📖 icon + Right step count/⏳ timer
- Expanded View (long press): Full scripture text + step count/timer
- Minimal View (when overlapping other apps): 📖 icon only

For iPhone 13 and earlier:
- Lock screen rectangular widget area shows verse excerpt
- Update notifications appear as top banner when data changes

[Server-Free Architecture]

- pushType = nil (explicitly no server push)
- Data sharing via UserDefaults App Group only
- HealthKit reads device-local data only
- Fully functional offline
- No API misuse (not using server to extend 8-hour session limit)

[Recommended Testing Steps for App Review]

1. Basic Functionality:
   - Install app
   - Tap "Start Session" button
   - Select a scripture verse
   - When HealthKit permission popup appears: tap "Allow"
   - Wait 30 seconds
   - Check lock screen: Should show blue bar with verse + 👣 step count

2. Dynamic Island Testing (iPhone 14+ required):
   - Long press on Dynamic Island (status bar)
   - Expanded View should show complete verse text + step count
   - Tap outside to close
   - Compact View should show 📖 (left) + step count (right)
   - Wait 30 more seconds
   - Right-side number should increase (real-time update verification)

3. HealthKit Permission Denied Scenario:
   - Completely delete app
   - Reinstall fresh
   - Tap "Start Session", select verse
   - When HealthKit permission popup appears: tap "Don't Allow"
   - Wait 30 seconds
   - Check lock screen: Should show ⏱️ timer instead of 👣 steps
   - Verify timer counts up in real-time (no crashes, fully functional)
   - This demonstrates proper fallback implementation

4. Custom Background Photo (Optional):
   - In app settings, select "Background Image"
   - Choose photo from album
   - Restart Live Activity
   - Lock screen bar displays selected image as background
   - Verse text appears over dark overlay for readability

[Technical Stack]

- Primary Language: Flutter (Dart), iOS native (Swift)
- Frameworks: ActivityKit, HealthKit, UserDefaults
- Minimum iOS Version: 16.2

[Additional Notes for Reviewers]

- This app uses HealthKit API for "real-time changing user activity data,"
  not static content display. Complies fully with Apple's Live Activities Guidelines.

- Either step count or timer is ALWAYS updating in real-time, satisfying
  Apple's core requirement that Live Activities must display "live, changing data."

- Privacy Assurance: All HealthKit data is read locally on-device.
  No data transmission to external servers. No user tracking or analytics
  servers involved.

- The 8-hour session limit is honored as-is (iOS enforces this automatically).
  No attempts to circumvent the limit via background pushes or server calls.

- Soft Prompt UX: Before requesting HealthKit permission, app shows
  an in-app explanation sheet, ensuring users understand the purpose
  before OS system popup appears.

=================================================
```

---

## 📋 작성 및 제출 가이드

### 제출 전 체크리스트:

- [ ] 한국어 버전 또는 영어 버전 중 하나 선택
- [ ] 글로벌 출시 계획이라면 영어 버전 사용
- [ ] App Store Connect에서 빌드 선택 후 "심사 정보" → "심사 노트" 필드에 붙여넣기
- [ ] 띄어쓰기, 줄 바꿈 확인 (포맷팅 유지)
- [ ] 테스트 디바이스 명시 (iPhone 14 Pro, iPhone 13 등)

### 제출 단계:

1. **App Store Connect 로그인**
   ```
   https://appstoreconnect.apple.com
   ```

2. **앱 선택 → 빌드 선택**

3. **"정보" 또는 "빌드" 섹션**
   ```
   심사 정보 → 심사 노트 필드
   ```

4. **위 내용 붙여넣기**

5. **"심사용으로 제출" 클릭**

---

## 🎯 왜 이런 내용을 써야 할까?

Apple 심사팀이 확인하려는 것:

| 항목 | 심사팀 질문 | 우리의 답변 |
|------|-----------|----------|
| **HealthKit 사용 정당성** | 왜 걸음 수를 읽나? | "실시간 사용자 활동 표시"라고 명시 |
| **Live Activities 올바른 사용** | 정적 텍스트 아닌가? | "타이머도 실시간이므로 항상 동적" |
| **API 오용** | 서버로 무한 연장? | "pushType=nil, 로컬만 사용" |
| **권한 거절 시 대응** | 앱이 망가지나? | "타이머로 자동 전환, 완전 정상 작동" |
| **테스트 방법** | 어떻게 테스트하지? | 구체적 단계별 가이드 제공 |

---

**최종 확인:** 한국 또는 영어 중 필요한 버전을 복사해서 App Store Connect에 붙여넣으면 됩니다! ✅
