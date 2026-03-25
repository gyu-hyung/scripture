import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/verse.dart';
import '../services/bible_service.dart';
import '../services/widget_service.dart';
import '../utils/constants.dart';

final bibleServiceProvider = Provider<BibleService>((ref) {
  return BibleService();
});

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService(ref.read(bibleServiceProvider));
});

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
  SelectedCategoryNotifier.new,
);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => AppConstants.categories.first;

  void select(String category) => state = category;
}

/// 현재 고정 상태
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

/// 오늘의 말씀 (랜덤 인기 구절, 매일 변경)
final dailyVerseProvider = AsyncNotifierProvider<DailyVerseNotifier, Verse?>(
  DailyVerseNotifier.new,
);

class DailyVerseNotifier extends AsyncNotifier<Verse?> {
  @override
  Future<Verse?> build() async {
    final widgetService = ref.read(widgetServiceProvider);
    await widgetService.checkAndUpdateDailyVerseIfNeeded();
    return await widgetService.getDailyVerse();
  }

  void refresh() => ref.invalidateSelf();
}

/// 사용자가 선택한 고정 말씀
final pinnedVerseProvider = AsyncNotifierProvider<PinnedVerseNotifier, Verse?>(
  PinnedVerseNotifier.new,
);

class PinnedVerseNotifier extends AsyncNotifier<Verse?> {
  @override
  Future<Verse?> build() async {
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

/// 카테고리별 말씀 목록 (레거시)
final verseListProvider =
    FutureProvider.family<List<Verse>, String>((ref, category) async {
  final bibleService = ref.read(bibleServiceProvider);
  return await bibleService.getPopularVerses(
    category: category == '전체' ? null : category,
  );
});
