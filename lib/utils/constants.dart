class AppConstants {
  static const String appName = '말씀위젯';
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

  // Categories
  static const List<String> categories = [
    '전체',
    '위로',
    '감사',
    '소망',
    '사랑',
    '믿음',
    '평안',
    '지혜',
  ];
}
