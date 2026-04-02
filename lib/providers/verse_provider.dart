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
    await widgetService.pinVerse(verse, themeId: themeId);
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
