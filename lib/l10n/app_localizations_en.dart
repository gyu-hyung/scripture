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

  @override
  String get tapToRead => 'Tap to read';

  @override
  String get pinThisVerse => 'Pin This Verse';

  @override
  String get searchBible => 'Search the Bible';

  @override
  String get enterSearchTerm => 'Enter a search term';

  @override
  String get noSearchResults => 'No results found';

  @override
  String searchResultCount(int count) {
    return '$count verses found';
  }

  @override
  String chapterLabel(int chapter) {
    return 'Ch. $chapter';
  }

  @override
  String verseLabel(int verse) {
    return 'v. $verse';
  }

  @override
  String get bibleNavigator => 'Navigate Bible';

  @override
  String get columnBook => 'Book';

  @override
  String get columnChapter => 'Ch.';

  @override
  String get columnVerse => 'V.';

  @override
  String get noData => 'No data';

  @override
  String get sectionPentateuch => 'Pentateuch';

  @override
  String get sectionHistorical => 'Historical';

  @override
  String get sectionPoetic => 'Poetic';

  @override
  String get sectionMajorProphets => 'Major Prophets';

  @override
  String get sectionMinorProphets => 'Minor Prophets';

  @override
  String get sectionGospels => 'Gospels';

  @override
  String get sectionActs => 'Acts';

  @override
  String get sectionPauline => 'Pauline Epistles';

  @override
  String get sectionGeneral => 'General Epistles';

  @override
  String get sectionRevelation => 'Revelation';

  @override
  String get widgetThemeTitle => 'Widget Theme';

  @override
  String get pinToWidget => 'Pin to Widget';

  @override
  String get themeModernDark => 'Modern Dark';

  @override
  String get themeMinimalistLight => 'Minimalist Light';

  @override
  String get themeSereneBlue => 'Serene Blue';

  @override
  String get themeNatureGreen => 'Nature Green';
}
