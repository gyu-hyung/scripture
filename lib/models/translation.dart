/// 성경 번역본 모델
///
/// 언어별 다중 번역본 지원:
///   Translation.byLanguage['ko'] → 개역개정, 개역한글, ...
///   Translation.byLanguage['en'] → KJV, WEB, ASV, ...
class Translation {
  final String id;          // 'ko_kor', 'en_kjv', 'en_web' ...
  final String language;    // 'ko', 'en', 'ja', 'zh' ...
  final String name;        // '개역개정', 'King James Version'
  final String shortName;   // '개역개정', 'KJV'
  final String dbFileName;  // 'bible.db', 'en_kjv.db'
  final bool isBundled;     // true = 앱에 포함, false = 다운로드 필요
  final String license;     // 'proprietary', 'public_domain', 'cc0'

  const Translation({
    required this.id,
    required this.language,
    required this.name,
    required this.shortName,
    required this.dbFileName,
    this.isBundled = false,
    this.license = 'public_domain',
  });

  /// 언어 코드 → 표시 이름 매핑
  static const Map<String, String> languageNames = {
    'ko': '한국어',
    'en': 'English',
    'ja': '日本語',
    'zh': '中文',
    'es': 'Español',
    'pt': 'Português',
    'de': 'Deutsch',
    'fr': 'Français',
    'ru': 'Русский',
    'ar': 'العربية',
    'id': 'Indonesia',
    'vi': 'Tiếng Việt',
  };

  /// 이 번역본의 언어 표시 이름
  String get languageDisplayName =>
      languageNames[language] ?? language.toUpperCase();

  // ─── 번들 포함 번역본 ───────────────────────────────────────────────────

  static const Translation koKor = Translation(
    id: 'ko_kor',
    language: 'ko',
    name: '개역개정',
    shortName: '개역개정',
    dbFileName: 'bible.db',
    isBundled: true,
    license: 'proprietary',   // 대한성서공회 비영리 라이선스 신청 필요
  );

  static const Translation enKjv = Translation(
    id: 'en_kjv',
    language: 'en',
    name: 'King James Version',
    shortName: 'KJV',
    dbFileName: 'en_kjv.db',
    isBundled: true,
    license: 'public_domain',
  );

  // ─── 다운로드 예정 번역본 (향후 추가) ────────────────────────────────────

  static const Translation enWeb = Translation(
    id: 'en_web',
    language: 'en',
    name: 'World English Bible',
    shortName: 'WEB',
    dbFileName: 'en_web.db',
    license: 'public_domain',
  );

  static const Translation enAsv = Translation(
    id: 'en_asv',
    language: 'en',
    name: 'American Standard Version',
    shortName: 'ASV',
    dbFileName: 'en_asv.db',
    license: 'public_domain',
  );

  static const Translation esRv09 = Translation(
    id: 'es_rv09',
    language: 'es',
    name: 'Reina-Valera 1909',
    shortName: 'RV1909',
    dbFileName: 'es_rv09.db',
    license: 'public_domain',
  );

  static const Translation ptAcr = Translation(
    id: 'pt_acr',
    language: 'pt',
    name: 'Almeida Corrigida e Revisada',
    shortName: 'ACR',
    dbFileName: 'pt_acr.db',
    license: 'public_domain',
  );

  static const Translation deLuth = Translation(
    id: 'de_luth',
    language: 'de',
    name: 'Lutherbibel 1912',
    shortName: 'LUT1912',
    dbFileName: 'de_luth.db',
    license: 'public_domain',
  );

  static const Translation frLsg = Translation(
    id: 'fr_lsg',
    language: 'fr',
    name: 'Louis Segond 1910',
    shortName: 'LSG',
    dbFileName: 'fr_lsg.db',
    license: 'public_domain',
  );

  static const Translation ruSynodal = Translation(
    id: 'ru_synodal',
    language: 'ru',
    name: 'Синодальный перевод',
    shortName: 'SYNODAL',
    dbFileName: 'ru_synodal.db',
    license: 'public_domain',
  );

  // ─── 언어별 번역본 레지스트리 ─────────────────────────────────────────────
  //
  // 새 번역본 추가 시 여기에만 등록하면 전체 UI에 자동 반영됩니다.

  static const Map<String, List<Translation>> byLanguage = {
    'ko': [koKor],
    'en': [enKjv, enWeb, enAsv],
    'es': [esRv09],
    'pt': [ptAcr],
    'de': [deLuth],
    'fr': [frLsg],
    'ru': [ruSynodal],
  };

  /// 현재 앱에 번들된 번역본 목록
  static List<Translation> get bundled =>
      all.where((t) => t.isBundled).toList();

  /// 전체 번역본 목록 (번들 + 다운로드 예정)
  static List<Translation> get all =>
      byLanguage.values.expand((list) => list).toList();

  /// ID로 번역본 찾기
  static Translation? findById(String id) =>
      all.where((t) => t.id == id).firstOrNull;

  /// 기기 locale 기반 기본 번역본 (해당 언어 첫 번째 번들 번역본)
  static Translation defaultFor(String languageCode) {
    final list = byLanguage[languageCode];
    if (list != null) {
      final bundledFirst = list.where((t) => t.isBundled).firstOrNull;
      if (bundledFirst != null) return bundledFirst;
    }
    return enKjv; // 최종 폴백
  }

  @override
  bool operator ==(Object other) =>
      other is Translation && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Translation($id)';
}
