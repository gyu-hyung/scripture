// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bible Widget';

  @override
  String get pinnedVerseTitle => 'My Pinned Verse';

  @override
  String get dailyVerseTitle => 'Today\'s Verse';

  @override
  String get selectVerse => 'Select Verse';

  @override
  String get selectVerseTooltip => 'Select';

  @override
  String get noPinnedVerse => 'No verse pinned yet.\nTap below to select one.';

  @override
  String get dailyVerseLoading => 'Loading today\'s verse...';

  @override
  String get unpin => 'Unpin';

  @override
  String errorMsg(String error) {
    return 'Error: $error';
  }

  @override
  String get categoryAll => 'All';

  @override
  String get categoryComfort => 'Comfort';

  @override
  String get categoryThanksgiving => 'Thanksgiving';

  @override
  String get categoryHope => 'Hope';

  @override
  String get categoryLove => 'Love';

  @override
  String get categoryFaith => 'Faith';

  @override
  String get categoryPeace => 'Peace';

  @override
  String get categoryWisdom => 'Wisdom';

  @override
  String get oldTestament => 'Old Testament';

  @override
  String get newTestament => 'New Testament';

  @override
  String booksCount(int count) {
    return '$count books';
  }

  @override
  String get selectBook => 'Select a Book';

  @override
  String bookSelectChapter(String book) {
    return '$book — Select a Chapter';
  }

  @override
  String bookChapterSelectVerse(String book, int chapter) {
    return '$book Ch.$chapter — Select a Verse';
  }

  @override
  String get backToBookSelect => 'Back to Book';

  @override
  String get backToChapterSelect => 'Back to Chapter';

  @override
  String get bookBreadcrumb => 'Bible >';

  @override
  String chapterBreadcrumb(int chapter) {
    return 'Ch.$chapter >';
  }

  @override
  String verseSet(String reference) {
    return '$reference has been set.';
  }

  @override
  String get setThisVerse => 'Set This Verse';

  @override
  String get noChapterInfo => 'Chapter information unavailable';

  @override
  String get noVerseInfo => 'Verse information unavailable';
}
