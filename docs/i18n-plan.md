# Scripture 앱 국제화(i18n) 계획

## 현황 파악

현재 하드코딩된 한국어 문자열이 다음 위치에 분산:
- `home_screen.dart` — UI 레이블, 버튼, 메시지 (~15개)
- `bible_picker_screen.dart` — 브레드크럼, 타이틀, 버튼 (~10개)
- `constants.dart` — `appName`, `categories` 배열
- `services/` — 오류 메시지

성경 콘텐츠 자체도 한국어(개역개정) 전용 SQLite DB.

---

## Phase 1 — Flutter UI 국제화

### 패키지 추가

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.0
```

### 파일 구조

```
lib/
  l10n/
    app_ko.arb   # 한국어 (기본)
    app_en.arb   # 영어
```

### ARB 예시 (`app_ko.arb`)

```json
{
  "appName": "말씀위젯",
  "sectionPinned": "내가 선택한 말씀",
  "sectionDaily": "오늘의 말씀",
  "selectVerse": "말씀 선택하기",
  "unpinVerse": "고정 해제",
  "emptyPinned": "아직 말씀을 선택하지 않았어요\n아래 버튼으로 말씀을 선택해보세요",
  "emptyDailyLoading": "오늘의 말씀을 불러오는 중...",
  "pickBibleTitle": "성경을 선택하세요",
  "pickChapterTitle": "{book} — 장을 선택하세요",
  "@pickChapterTitle": { "placeholders": { "book": {} } },
  "pickVerseTitle": "{book} {chapter}장 — 절을 선택하세요",
  "@pickVerseTitle": { "placeholders": { "book": {}, "chapter": {} } },
  "setVerseConfirm": "이 말씀으로 설정하기",
  "verseSetSuccess": "{reference} 말씀이 설정되었습니다",
  "@verseSetSuccess": { "placeholders": { "reference": {} } },
  "oldTestament": "구약",
  "newTestament": "신약",
  "bookCount": "{count}권",
  "@bookCount": { "placeholders": { "count": {} } },
  "backToBook": "성경 선택으로",
  "backToChapter": "장 선택으로",
  "errorPrefix": "오류: {message}",
  "@errorPrefix": { "placeholders": { "message": {} } },
  "cannotLoadChapter": "장 정보를 불러올 수 없습니다",
  "cannotLoadVerse": "절 정보를 불러올 수 없습니다",
  "categoryAll": "전체",
  "categoryComfort": "위로",
  "categoryThanks": "감사",
  "categoryHope": "소망",
  "categoryLove": "사랑",
  "categoryFaith": "믿음",
  "categoryPeace": "평안",
  "categoryWisdom": "지혜"
}
```

---

## Phase 2 — 성경 번역본 다국어 지원

### 데이터 설계

현재 단일 DB(`bible.db`) → **번역본별 별도 DB 파일** 방식 권장:

```
assets/db/
  bible_ko_krv.db    # 개역개정 (한국어)
  bible_en_kjv.db    # King James Version (영어)
  bible_en_esv.db    # English Standard Version (영어)
  bible_zh_cuv.db    # 和合本 (중국어, 선택적)
```

각 DB 스키마는 동일하게 유지 (`books`, `verses` 테이블).

### 번역본 메타데이터 (`translation_meta.dart`)

```dart
class BibleTranslation {
  final String id;       // 'ko_krv'
  final String name;     // '개역개정'
  final String locale;   // 'ko'
  final String dbPath;   // 'assets/db/bible_ko_krv.db'
}

const kAvailableTranslations = [
  BibleTranslation(id: 'ko_krv', name: '개역개정', locale: 'ko', ...),
  BibleTranslation(id: 'en_kjv', name: 'King James Version', locale: 'en', ...),
  BibleTranslation(id: 'en_esv', name: 'English Standard Version', locale: 'en', ...),
];
```

### Provider 변경

```dart
// 현재: BibleService 단일 인스턴스
// 변경: selectedTranslationProvider → BibleService 인스턴스 동적 생성

final selectedTranslationProvider = StateNotifierProvider<...>(
  (ref) => BibleTranslationNotifier('ko_krv'), // 기본값
);

final bibleServiceProvider = Provider((ref) {
  final translation = ref.watch(selectedTranslationProvider);
  return BibleService(dbPath: translation.dbPath);
});
```

---

## Phase 3 — 번역본 선택 UI

`HomeScreen` AppBar에 번역본 토글 또는 설정 화면 추가:

```
[말씀위젯]  [개역개정 ▾]  [성경 선택 아이콘]
```

번역본 변경 시:
1. `selectedTranslationProvider` 업데이트 (`SharedPreferences`에 저장)
2. `bibleServiceProvider` 자동 재빌드
3. `pinnedVerse`는 번역본 변경 시 초기화 또는 같은 절 번호로 다른 번역 로드

---

## Phase 4 — 위젯(네이티브) 국제화

### Android (`AppWidgetProvider` / `RemoteViews`)

- `res/values/strings.xml` (기본, 한국어)
- `res/values-en/strings.xml` (영어)
- 위젯 레이블만 해당 (`widget_label` 등)

### iOS (WidgetKit)

- `InfoPlist.strings` (ko/en)
- `Localizable.strings`

---

## 작업 순서

| 단계 | 작업 | 난이도 |
|------|------|--------|
| 1 | `flutter_localizations` + `intl` 추가, ARB 파일 생성 | 낮음 |
| 2 | 모든 하드코딩 문자열 → `AppLocalizations.of(context).xxx` 교체 | 낮음 |
| 3 | 영어 번역본 DB 준비 (KJV는 공개 도메인) | 중간 |
| 4 | `BibleTranslation` 모델 + `selectedTranslationProvider` 추가 | 중간 |
| 5 | `BibleService` DB 경로 파라미터화 | 낮음 |
| 6 | 번역본 선택 UI 구현 | 낮음 |
| 7 | 네이티브 위젯 문자열 국제화 | 중간 |

---

## 주요 결정사항 (확인 필요)

1. **지원 언어 우선순위** — 영어 필수? 중국어/일본어도 포함?
2. **영어 번역본** — KJV(공개 도메인) 우선? ESV/NIV는 라이선스 비용 발생
3. **앱 언어 vs 성경 언어 분리** — UI 언어와 성경 번역본을 별도로 선택할 수 있게 할지 (예: 영어 UI + 개역개정)
4. **기존 핀 데이터** — 번역본 변경 시 pinned verse 처리 방식
