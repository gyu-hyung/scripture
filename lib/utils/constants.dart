class AppConstants {
  static const String appName = 'Scripture';
  static const String dbName = 'bible.db';
  static const String widgetAndroidName = 'ScriptureWidgetProvider';
  static const String widgetIosName = 'ScriptureWidget';
  static const String appGroupId = 'group.com.scripture.scripture';

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

  // HomeWidget (Native Widget) Shared Keys
  static const String keyWidgetVerseText = 'verse_text';
  static const String keyWidgetVerseRef = 'verse_ref';
  static const String keyWidgetIsPinned = 'is_pinned';
  static const String keyWidgetTheme = 'widget_theme';

  // Theme IDs
  static const String themeModernDark = 'modern_dark';
  static const String themeMinimalistLight = 'minimalist_light';
  static const String themeSereneBlue = 'serene_blue';
  static const String themeNatureGreen = 'nature_green';

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
