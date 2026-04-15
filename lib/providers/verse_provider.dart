import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/verse.dart';
import '../utils/constants.dart';
import 'bible_provider.dart';
import 'translation_provider.dart';

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

  /// 말씀 고정 및 Live Activity 시작.
  /// 반환값: null이면 성공, 'ACTIVITIES_DISABLED'이면 Live Activity 권한 거부.
  Future<String?> pinVerse(Verse verse, {String? themeId}) async {
    state = const AsyncValue.loading();
    final widgetService = ref.read(widgetServiceProvider);
    final liveActivityService = ref.read(liveActivityServiceProvider);

    await widgetService.pinVerse(verse, themeId: themeId);
    final resolvedTheme = themeId ?? await widgetService.getCurrentThemeId();

    // UI를 먼저 업데이트
    state = AsyncValue.data(verse);
    ref.read(isPinnedProvider.notifier).refresh();

    // 세션 시작 (Live Activity)
    try {
      return await liveActivityService.startSession(verse, resolvedTheme);
    } catch (e) {
      print('[PinnedVerseNotifier] pinVerse session start failed: $e');
      return null;
    }
  }

  Future<void> unpinVerse() async {
    state = const AsyncValue.loading();
    final widgetService = ref.read(widgetServiceProvider);
    final liveActivityService = ref.read(liveActivityServiceProvider);

    // 고정 해제 = 세션 종료
    await liveActivityService.stopSession();
    await widgetService.unpinVerse();

    state = const AsyncValue.data(null);
    ref.read(isPinnedProvider.notifier).refresh();
  }

  Future<void> stopSessionOnly() async {
    final liveActivityService = ref.read(liveActivityServiceProvider);
    await liveActivityService.stopSession();
  }

  Future<String?> restartSession() async {
    final verse = state.value;
    if (verse == null) return null;
    final widgetService = ref.read(widgetServiceProvider);
    final liveActivityService = ref.read(liveActivityServiceProvider);
    final themeId = await widgetService.getCurrentThemeId();
    try {
      return await liveActivityService.startSession(verse, themeId);
    } catch (e) {
      print('[PinnedVerseNotifier] restartSession failed: $e');
      return null;
    }
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
