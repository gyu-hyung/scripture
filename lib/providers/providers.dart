import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation.dart';
import '../models/verse.dart';
import '../services/bible_service.dart';
import '../services/widget_service.dart';
import '../utils/constants.dart';

// ─── 번역본 선택 ──────────────────────────────────────────────────────────

final selectedTranslationProvider =
    AsyncNotifierProvider<SelectedTranslationNotifier, Translation>(
  SelectedTranslationNotifier.new,
);

class SelectedTranslationNotifier extends AsyncNotifier<Translation> {
  static const _key = 'selected_translation_id';

  @override
  Future<Translation> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_key);

    if (savedId != null) {
      final found = Translation.bundled.where((t) => t.id == savedId).firstOrNull;
      if (found != null) return found;
    }

    // 저장된 값 없으면 기기 locale 기반 기본값
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return Translation.defaultFor(locale.languageCode);
  }

  Future<void> setTranslation(Translation translation) async {
    state = AsyncValue.data(translation);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, translation.id);

    // 번역본 바뀌면 DB 캐시 초기화 후 구절 갱신
    BibleService.clearAllCache();
    ref.invalidate(pinnedVerseProvider);
  }
}

// ─── 서비스 ───────────────────────────────────────────────────────────────

final bibleServiceProvider = Provider<BibleService>((ref) {
  final translationAsync = ref.watch(selectedTranslationProvider);
  final translation = translationAsync.when(
    data: (t) => t,
    loading: () => Translation.bundled[0],
    error: (e, st) => Translation.bundled[0],
  );
  return BibleService(translation);
});

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService(ref.read(bibleServiceProvider));
});

// ─── 카테고리 선택 ───────────────────────────────────────────────────────

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
  SelectedCategoryNotifier.new,
);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => AppConstants.categoryAll;

  void select(String category) => state = category;
}

// ─── 고정 여부 ────────────────────────────────────────────────────────────

final isPinnedProvider = AsyncNotifierProvider<IsPinnedNotifier, bool>(
  IsPinnedNotifier.new,
);

class IsPinnedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final widgetService = ref.read(widgetServiceProvider);
    return await widgetService.isPinned();
  }

  void refresh() => ref.invalidateSelf();
}

// ─── 고정 말씀 ────────────────────────────────────────────────────────────

final pinnedVerseProvider = AsyncNotifierProvider<PinnedVerseNotifier, Verse?>(
  PinnedVerseNotifier.new,
);

class PinnedVerseNotifier extends AsyncNotifier<Verse?> {
  @override
  Future<Verse?> build() async {
    // 번역본이 바뀌면 이 provider도 자동으로 rebuild
    ref.watch(selectedTranslationProvider);

    final widgetService = ref.read(widgetServiceProvider);
    return await widgetService.getPinnedVerse();
  }

  Future<void> pinVerse(Verse verse) async {
    state = const AsyncValue.loading();
    final widgetService = ref.read(widgetServiceProvider);
    await widgetService.pinVerse(verse);
    state = AsyncValue.data(verse);
    ref.read(isPinnedProvider.notifier).refresh();
  }

  Future<void> unpinVerse() async {
    state = const AsyncValue.loading();
    final widgetService = ref.read(widgetServiceProvider);
    await widgetService.unpinVerse();
    state = const AsyncValue.data(null);
    ref.read(isPinnedProvider.notifier).refresh();
  }

  void refresh() => ref.invalidateSelf();
}

// ─── 카테고리별 말씀 목록 ─────────────────────────────────────────────────

final verseListProvider =
    FutureProvider.family<List<Verse>, String>((ref, category) async {
  final bibleService = ref.read(bibleServiceProvider);
  return await bibleService.getPopularVerses(
    category: category == 'all' ? null : category,
  );
});
