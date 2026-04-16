class AppConstants {
  static const String appName = 'Scripture';
  static const String dbName = 'bible.db';
  static const String widgetAndroidName = 'ScriptureWidgetProvider';
  static const String widgetIosName = 'ScriptureWidgetV2';
  static const String appGroupId = 'group.com.jgh.malsseumdonghaeng';

  // SharedPreferences keys
  static const String keyCurrentVerseId = 'current_verse_id';
  static const String keyCurrentVerseText = 'current_verse_text';
  static const String keyCurrentVerseRef = 'current_verse_ref';
  static const String keyLastUpdateDate = 'last_update_date';
  static const String keyDailyVerseId = 'daily_verse_id';
  static const String keyCategory = 'selected_category';
  static const String keyFontSize = 'widget_font_size';
  static const String keyBackgroundStyle = 'widget_bg_style';
  static const String keyAutoRefresh = 'auto_refresh';
  static const String keyPinnedVerseId = 'pinned_verse_id';
  static const String keyIsPinned = 'is_pinned';
  static const String keyHasLaunchedBefore = 'has_launched_before';
  static const String keyVerseHistory = 'verse_history';

  // HomeWidget (Native Widget) Shared Keys
  static const String keyWidgetVerseText = 'verse_text';
  static const String keyWidgetVerseRef = 'verse_ref';
  static const String keyWidgetIsPinned = 'is_pinned';
  static const String keyWidgetTheme = 'widget_theme';

  // Theme IDs
  static const String themeModernDark = 'modern_dark';
  static const String themePureWhite = 'pure_white';
  static const String themePastelRed = 'pastel_red';
  static const String themePastelOrange = 'pastel_orange';
  static const String themePastelYellow = 'pastel_yellow';
  static const String themePastelGreen = 'pastel_green';
  static const String themePastelTeal = 'pastel_teal';
  static const String themePastelBlue = 'pastel_blue';
  static const String themePastelIndigo = 'pastel_indigo';
  static const String themePastelPurple = 'pastel_purple';

  // Custom photo storage key (App Group shared)
  static const String customPhotoBgFilename = 'widget_custom_bg.jpg';

  // Category keys (language-neutral, stored in DB and SharedPreferences)
  // Use l10n_utils.dart > localizeCategory() for display labels
  static const String categoryAll          = 'all';
  static const String categoryComfort      = 'comfort';
  static const String categoryThanksgiving = 'thanksgiving';
  static const String categoryHope         = 'hope';
  static const String categoryLove         = 'love';
  static const String categoryFaith        = 'faith';
  static const String categoryPeace        = 'peace';
  static const String categoryWisdom       = 'wisdom';

  static const List<String> categories = [
    categoryAll,
    categoryComfort,
    categoryThanksgiving,
    categoryHope,
    categoryLove,
    categoryFaith,
    categoryPeace,
    categoryWisdom,
  ];
}
