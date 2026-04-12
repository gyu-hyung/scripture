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

  Future<void> pinVerse(Verse verse, {String? themeId}) async {
    state = const AsyncValue.loading();
    final widgetService = ref.read(widgetServiceProvider);
    final liveActivityService = ref.read(liveActivityServiceProvider);

    await widgetService.pinVerse(verse, themeId: themeId);
    final resolvedTheme = themeId ?? await widgetService.getCurrentThemeId();

    // UI를 먼저 업데이트하고 세션은 비동기로 시작
    // (HealthKit 권한 팝업 대기 중 로딩이 길어지는 문제 방지)
    state = AsyncValue.data(verse);
    ref.read(isPinnedProvider.notifier).refresh();

    // 세션 시작 (Live Activity) — fire-and-forget
    liveActivityService.startSession(verse, resolvedTheme);
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
