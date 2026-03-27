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
}
