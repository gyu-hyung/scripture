// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '말씀위젯';

  @override
  String get pinnedVerseTitle => '내가 선택한 말씀';

  @override
  String get dailyVerseTitle => '오늘의 말씀';

  @override
  String get selectVerse => '말씀 선택하기';

  @override
  String get selectVerseTooltip => '말씀 선택';

  @override
  String get noPinnedVerse => '아직 말씀을 선택하지 않았어요\n아래 버튼으로 말씀을 선택해보세요';

  @override
  String get dailyVerseLoading => '오늘의 말씀을 불러오는 중...';

  @override
  String get unpin => '고정 해제';

  @override
  String errorMsg(String error) {
    return '오류: $error';
  }

  @override
  String get categoryAll => '전체';

  @override
  String get categoryComfort => '위로';

  @override
  String get categoryThanksgiving => '감사';

  @override
  String get categoryHope => '소망';

  @override
  String get categoryLove => '사랑';

  @override
  String get categoryFaith => '믿음';

  @override
  String get categoryPeace => '평안';

  @override
  String get categoryWisdom => '지혜';

  @override
  String get oldTestament => '구약';

  @override
  String get newTestament => '신약';

  @override
  String booksCount(int count) {
    return '$count권';
  }

  @override
  String get selectBook => '성경을 선택하세요';

  @override
  String bookSelectChapter(String book) {
    return '$book — 장을 선택하세요';
  }

  @override
  String bookChapterSelectVerse(String book, int chapter) {
    return '$book $chapter장 — 절을 선택하세요';
  }

  @override
  String get backToBookSelect => '성경 선택으로';

  @override
  String get backToChapterSelect => '장 선택으로';

  @override
  String get bookBreadcrumb => '성경 >';

  @override
  String chapterBreadcrumb(int chapter) {
    return '$chapter장 >';
  }

  @override
  String verseSet(String reference) {
    return '$reference 말씀이 설정되었습니다';
  }

  @override
  String get setThisVerse => '이 말씀으로 설정하기';

  @override
  String get noChapterInfo => '장 정보를 불러올 수 없습니다';

  @override
  String get noVerseInfo => '절 정보를 불러올 수 없습니다';

  @override
  String get tapToRead => '탭하여 본문 보기';

  @override
  String get pinThisVerse => '이 말씀 고정하기';

  @override
  String get searchBible => '성경 단어 검색';

  @override
  String get enterSearchTerm => '검색어를 입력하세요';

  @override
  String get noSearchResults => '검색 결과가 없습니다';

  @override
  String searchResultCount(int count) {
    return '$count개 구절 검색됨';
  }

  @override
  String chapterLabel(int chapter) {
    return '$chapter장';
  }

  @override
  String verseLabel(int verse) {
    return '$verse절';
  }

  @override
  String get bibleNavigator => '성경 이동';

  @override
  String get columnBook => '책';

  @override
  String get columnChapter => '장';

  @override
  String get columnVerse => '절';

  @override
  String get noData => '데이터 없음';

  @override
  String get sectionPentateuch => '모세오경';

  @override
  String get sectionHistorical => '역사서';

  @override
  String get sectionPoetic => '시가서';

  @override
  String get sectionMajorProphets => '대선지서';

  @override
  String get sectionMinorProphets => '소선지서';

  @override
  String get sectionGospels => '복음서';

  @override
  String get sectionActs => '역사서(신)';

  @override
  String get sectionPauline => '바울서신';

  @override
  String get sectionGeneral => '공동서신';

  @override
  String get sectionRevelation => '예언서(신)';

  @override
  String get widgetThemeTitle => '위젯 테마 선택';

  @override
  String get pinToWidget => '위젯에 고정하기';

  @override
  String get themeModernDark => '모던 다크';

  @override
  String get themeMinimalistLight => '미니멀 라이트';

  @override
  String get themeSereneBlue => '세린 블루';

  @override
  String get themeNatureGreen => '네이처 그린';
}
