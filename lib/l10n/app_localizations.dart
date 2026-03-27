import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Bible Widget'**
  String get appTitle;

  /// Section title for pinned verse
  ///
  /// In en, this message translates to:
  /// **'My Pinned Verse'**
  String get pinnedVerseTitle;

  /// Section title for daily verse
  ///
  /// In en, this message translates to:
  /// **'Today\'s Verse'**
  String get dailyVerseTitle;

  /// Button text for selecting a verse
  ///
  /// In en, this message translates to:
  /// **'Select Verse'**
  String get selectVerse;

  /// Tooltip for select verse icon button
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectVerseTooltip;

  /// Empty state message for pinned verse
  ///
  /// In en, this message translates to:
  /// **'No verse pinned yet.\nTap below to select one.'**
  String get noPinnedVerse;

  /// Loading message for daily verse
  ///
  /// In en, this message translates to:
  /// **'Loading today\'s verse...'**
  String get dailyVerseLoading;

  /// Button text to unpin a verse
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMsg(String error);

  /// Category: all verses
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// Category: comfort verses
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get categoryComfort;

  /// Category: thanksgiving verses
  ///
  /// In en, this message translates to:
  /// **'Thanksgiving'**
  String get categoryThanksgiving;

  /// Category: hope verses
  ///
  /// In en, this message translates to:
  /// **'Hope'**
  String get categoryHope;

  /// Category: love verses
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get categoryLove;

  /// Category: faith verses
  ///
  /// In en, this message translates to:
  /// **'Faith'**
  String get categoryFaith;

  /// Category: peace verses
  ///
  /// In en, this message translates to:
  /// **'Peace'**
  String get categoryPeace;

  /// Category: wisdom verses
  ///
  /// In en, this message translates to:
  /// **'Wisdom'**
  String get categoryWisdom;

  /// Old Testament label
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// New Testament label
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// Number of books in testament
  ///
  /// In en, this message translates to:
  /// **'{count} books'**
  String booksCount(int count);

  /// Title for book selection step
  ///
  /// In en, this message translates to:
  /// **'Select a Book'**
  String get selectBook;

  /// Title for chapter selection step
  ///
  /// In en, this message translates to:
  /// **'{book} — Select a Chapter'**
  String bookSelectChapter(String book);

  /// Title for verse selection step
  ///
  /// In en, this message translates to:
  /// **'{book} Ch.{chapter} — Select a Verse'**
  String bookChapterSelectVerse(String book, int chapter);

  /// Back button text to return to book selection
  ///
  /// In en, this message translates to:
  /// **'Back to Book'**
  String get backToBookSelect;

  /// Back button text to return to chapter selection
  ///
  /// In en, this message translates to:
  /// **'Back to Chapter'**
  String get backToChapterSelect;

  /// Breadcrumb label for Bible/book level
  ///
  /// In en, this message translates to:
  /// **'Bible >'**
  String get bookBreadcrumb;

  /// Breadcrumb label for chapter level
  ///
  /// In en, this message translates to:
  /// **'Ch.{chapter} >'**
  String chapterBreadcrumb(int chapter);

  /// Snackbar message when a verse is pinned
  ///
  /// In en, this message translates to:
  /// **'{reference} has been set.'**
  String verseSet(String reference);

  /// Button to confirm verse selection in preview
  ///
  /// In en, this message translates to:
  /// **'Set This Verse'**
  String get setThisVerse;

  /// Error when chapter info cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Chapter information unavailable'**
  String get noChapterInfo;

  /// Error when verse info cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Verse information unavailable'**
  String get noVerseInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
